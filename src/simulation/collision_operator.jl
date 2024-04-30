function collision_step!(mesh, time_step, species, thread_id, sim_channel, plot_type)
    for index in local_indices(mesh.cells, thread_id)
        cell = mesh.cells[index]
        particles = cell.particles

        N, u, σ² = sample_moments(particles)

        ρ = density(N, species, mesh)
        T = temperature(σ², species)
        P = collision_probability(ρ, T, time_step, species)

        relax!(particles, P, u, √σ²)
        conservation_step!(particles, u, σ²)

        # Send mesh data to plot
        if plot_type != :particles
            set!(sim_channel) do data
                data.mesh_values[index] = norm(eval(plot_type)) # ρ
            end
        end
    end
end

function relax!(particles, P, u, σ)
    for p in particles
        rand() > P && continue
        p.velocity = u + σ * randn(typeof(p.velocity))
    end
end

function conservation_step!(particles, u, σ²)
    _, uₙ, σₙ² = sample_moments(particles)

    ratio = √(σ² / σₙ²)

    for p in particles
        p.velocity = u + ratio * (p.velocity - uₙ)
    end
end

function sample_moments(particles)
    N = length(particles)
    ∑v = sum(p.velocity for p in particles; init=zero(Vec3{Float64}))
    ∑v² = sum(p.velocity ⋅ p.velocity for p in particles; init=0)
    ∑c² = ∑v² - ∑v ⋅ ∑v / N

    mean = ∑v / N
    variance = ∑c² / (3(N - 1))
    return N, mean, variance
end

function collision_probability(ρ, T, Δt, species)
    ν = relaxation_frequency(ρ, T, species)
    return 1 - exp(-Δt * ν)
end

function relaxation_frequency(ρ, T, species)
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