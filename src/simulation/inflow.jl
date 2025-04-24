struct InflowBC
    number_flux::Float64
    velocity::Float64
    most_probable_velocity::Float64

    function InflowBC(ρ, u, T, species)
        m, ω = species.mass, species.weighting

        uₘₚ = √(2 * BOLTZMANN_CONST * T / m)
        r = u / uₘₚ
        ṁ = 0.5 * (u * (erf(r) + 1) + uₘₚ / √π * exp(-(r)^2)) * ρ
        ṅ = ṁ / (m * ω)
        return new(ṅ, u, uₘₚ)
    end
end

function insert_particles!(particles, mesh, time_step)
    inflow_bc = mesh.inflow_bc[]
    xₚ, vₚ, Iₚ, free_indices = particles.position, particles.velocity, particles.index, particles.free_indices

    # Calculate number of particles to insert
    num_new_particles = stochastic_round(inflow_bc.number_flux * mesh.length[2] * time_step)

    # Find empty indices in the particle vector to insert new particles
    num_new_particles = find_empty_indices!(particles, num_new_particles)

    # Insert new particles
    @batch for i in 1:num_new_particles
        xₚ[free_indices[i]] = eltype(xₚ)(0, rand() * mesh.length[2])
        vₚ[free_indices[i]] = sample_inflow_velocity(inflow_bc.most_probable_velocity, inflow_bc.velocity)
        Iₚ[free_indices[i]] = index(xₚ[free_indices[i]], mesh)

        # Move back for a fraction of a time step to avoid particle clumping together
        xₚ[free_indices[i]] -= rand() * time_step * Vec2{Float64}(vₚ[free_indices[i]])
    end
end

function find_empty_indices!(particles, num_new_particles)
    num_free = 0
    for i in eachindex(particles.index)
        if particles.index[i][1] == -1
            num_free += 1
            particles.free_indices[num_free] = i
            num_free == num_new_particles && break
        end
    end
    return num_free
end