function collision_step!(particles, time_step, species, mesh, thread_id)
    for index in local_indices(mesh.cells, thread_id)
        cell = cells[index]

        N, u, σ² = sample_moments(cell.particles)

        ρ = density(N, species, mesh)
        T = temperature(σ², species)
        P = collision_probability(ρ, T, time_step, species)

        relax!(particles, P, u, √σ²)
        conservation_step!(particles, u, σ²)

        update!(output, index, ρ, u, T)
        #= TODO
        if type(output) == :density
            output[index] = ρ
        elseif type(output) == :velocity
            output[index] = norm(u)
        elseif type(output) == :temperature
            output[index] = T
        end
        =#
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
    ∑v = sum(p.velocity for p in particles)
    ∑v² = sum(p.velocity ⋅ p.velocity for p in particles)
    ∑c² = ∑v² - ∑v ⋅ ∑v / N

    mean = ∑v / N
    variance = ∑c² / (3(N - 1))
    return N, mean, variance
end

function collision_probability(ρ, T, time_step, species)
    ν = relaxation_frequency(ρ, T, species)
    return 1 - exp(-time_step * ν)
end

function relaxation_frequency(ρ, T, species)
    μ = dynamic_viscosity(T, species)
    return ρ * BOLTZMANN_CONST * T / (μ * species.mass)
end

density(N, species, mesh) = species.weighting * species.mass * N / cell_volume(mesh)

temperature(σ², species) = σ² * species.mass / BOLTZMANN_CONST

function dynamic_viscosity(T, species)
    return species.ref_viscosity * (T / species.ref_temperature)^species.ref_exponent
end