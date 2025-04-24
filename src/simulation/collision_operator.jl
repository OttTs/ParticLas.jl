function sum_up_particles!(particles, mesh)
    ∑v⁰, ∑v¹, ∑v² = mesh.∑∑v⁰, mesh.∑v¹, mesh.∑v²
    Iₚ, vₚ = particles.index, particles.velocity

    @batch for I in eachindex(∑v⁰)
        ∑v⁰[I] = zero(eltype(∑v⁰))
        ∑v¹[I] = zero(eltype(∑v¹))
        ∑v²[I] = zero(eltype(∑v²))
    end

    @batch for i in eachindex(Iₚ)
        Iₚ[i][1] <= 0 && continue
        ∑v⁰[Iₚ[i],Threads.threadid()] += 1
        ∑v¹[Iₚ[i],Threads.threadid()] += vₚ[i]
        ∑v²[Iₚ[i],Threads.threadid()] += sum(vₚ[i].^2)
    end
end

function calculate_relaxation_parameters!(mesh, species, time_step)
    ∑v⁰, ∑v¹, ∑v² = mesh.∑v⁰, mesh.∑v¹, mesh.∑v²
    ρ, u, T, Pᵣₑₗₐₓ, σ = mesh.density, mesh.velocity, mesh.temperature, mesh.relaxation_probability, mesh.scale_parameter
    ω, m, Tᵣ, ωᵣ = species.weighting, species.mass, species.ref_temperature, species.ref_exponent
    V = prod(cellsize(mesh))

    cell_indices = CartesianIndices(NUM_CELLS)
    @batch for I in cell_indices
        N, u[I], σ² = calculate_moments(∑v⁰, ∑v¹, ∑v², I)
        σ = iszero(σ²) ? zero(eltype(σ²)) : √σ²
        ρ[I] = ω * m * N / V
        T[I] = σ² * m / BOLTZMANN_CONST
        μ = μᵣ * (T / Tᵣ)^ωᵣ
        ν = ρ[I] * BOLTZMANN_CONST * T[I] / (μ * m)
        Pᵣₑₗₐₓ[I] = 1 - exp(-time_step * ν)
    end
end

function relax_particles!(particles, mesh)
    Iₚ, vₚ = particles.index, particles.velocity
    u, σ, Pᵣₑₗₐₓ = mesh.velocity, mesh.scale_parameter, mesh.relaxation_probability

    @batch for i in eachindex(Iₚ)
        rand() > Pᵣₑₗₐₓ[Iₚ[i]] && continue
        vₚ[i] = u[Iₚ[i]] + σ[Iₚ[i]] * randn(eltype(vₚ))
    end
end

function enforce_conservation!(particles, mesh)
    u, uₜₘₚ, σ, ratio = mesh.velocity, mesh.unconserved_velocity, mesh.scale_parameter, mesh.conservation_ratio
    Iₚ, vₚ = particles.index, particles.velocity

    cell_indices = CartesianIndices(NUM_CELLS)
    @batch for I in cell_indices
        _, uₜₘₚ[I], σ² = calculate_moments(∑v⁰, ∑v¹, ∑v², I)
        ratio[I] = iszero(σ²) ? zero(eltype(ratio)) : σ[I] / √σ²
    end

    @batch for i in eachindex(Iₚ)
        vₚ[i] = u[Iₚ[i]] + ratio[Iₚ[i]] * (vₚ[i] - uₜₘₚ[Iₚ[i]])
    end
end

function calculate_moments(∑v⁰, ∑v¹, ∑v², I)
    N = sum(@view(∑v⁰[I,:]))
    Nu = sum(@view(∑v¹[I,:]))
    Nu² = sum(@view(∑v²[I,:]))

    # Cell is empty
    N < 1 && return zero(eltype(∑v⁰)), zero(eltype(∑v¹)), zero(eltype(∑v²))

    u = Nu / N

    # Only 1 particle in cell
    N == 1 && return N, u, zero(eltype(∑v²))

    ∑c² = Nu² - sum(Nu.^2) / N
    σ² = ∑c² / (3(N - 1))
    return N, u, σ²
end