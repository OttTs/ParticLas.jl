function sum_up_particles!(particles, mesh)
    # Reset moments
    @batch for threadid in 1:Threads.nthreads(:default)
        for i in eachindex(mesh.cells)
            ∑ₚ = mesh.cells[i].raw_moments[threadid]
            ∑ₚ.v⁰ = 0
            ∑ₚ.v¹ = zero(typeof(∑ₚ.v¹))
            ∑ₚ.v² = 0
        end

        # Calculate new moments
        for p in particles
            ∑ₚ = mesh.cells[p.index].raw_moments[threadid]
            ∑ₚ.v⁰ += 1
            ∑ₚ.v¹ += p.velocity
            ∑ₚ.v² += p.velocity ⋅ p.velocity
        end
    end
end

function relaxation_parameters!(mesh, species, time_step)
    mesh_cells = mesh.cells
    @batch for i in eachindex(mesh_cells)
        cell = mesh_cells[i]

        N, cell.bulk_velocity, σ² = calculate_moments(cell.raw_moments)

        cell.scale_parameter = σ² <= 0 ? 0 : √σ²

        # We only need the density and temperature for the visualization!
        cell.density = density(N, species, mesh)
        cell.temperature = temperature(σ², species)
        cell.relaxation_probability = relaxation_probability(
            cell.density, cell.temperature, time_step, species
        )
    end
end

function relax_particles!(particles, mesh)
    @batch for p in particles
        cell = mesh.cells[p.index]
        rand() > cell.relaxation_probability && continue
        p.velocity = cell.bulk_velocity + cell.scale_parameter * randn(typeof(p.velocity))
    end
end

function conservation_parameters!(mesh)
    @batch for i in eachindex(mesh.cells)
        cell = mesh.cells[i]
        _, cell.tmp_bulk_velocity, σ² = calculate_moments(cell.raw_moments)
        cell.conservation_ratio = σ² <= 0 ? 0 : cell.scale_parameter / √(σ²)
    end
end

function conservation_step!(particles, mesh)
    @batch for p in particles
        cell = mesh.cells[p.index]
        p.velocity = cell.bulk_velocity +
            cell.conservation_ratio * (p.velocity - cell.tmp_bulk_velocity)
    end
end

function calculate_moments(raw_moments)
    N = sum(∑ₚ.v⁰ for ∑ₚ in raw_moments)
    ∑v = sum(∑ₚ.v¹ for ∑ₚ in raw_moments)
    ∑v² = sum(∑ₚ.v² for ∑ₚ in raw_moments)

    N < 1 && return N, zeros(typeof(∑v)), 0
    ∑c² = ∑v² - ∑v ⋅ ∑v / N
    mean = ∑v / N
    N < 2 && return N, mean, 0
    variance = ∑c² / (3(N - 1))
    return N, mean, variance
end

function relaxation_probability(ρ, T, Δt, species)
    ν = relaxation_frequency(ρ, T, species)
    return 1 - exp(-Δt * ν)
end

function relaxation_frequency(ρ, T, species)
    T <= 0 && return 0
    m = species.mass
    μ = dynamic_viscosity(
        T,
        species.ref_temperature,
        species.ref_viscosity,
        species.ref_exponent
    )
    return ρ * BOLTZMANN_CONST * T / (μ * m)
end

density(N, species, mesh) = species.weighting * species.mass * N / cellvolume(mesh)

temperature(σ², species) = σ² * species.mass / BOLTZMANN_CONST

dynamic_viscosity(T, Tᵣ, μᵣ, ωᵣ) = μᵣ * (T / Tᵣ)^ωᵣ