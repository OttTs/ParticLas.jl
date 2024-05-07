mutable struct InflowCondition
    number_flux::Float64 # per thread!
    velocity::Float64
    most_probable_velocity::Float64
    InflowCondition() = new(0, 0, 0)
end

function set!(c::InflowCondition, density, velocity, temperature, species)
    c.velocity = velocity
    c.most_probable_velocity = √(2 * BOLTZMANN_CONST * temperature / species.mass)

    ratio = velocity / c.most_probable_velocity
    mass_flux = 0.5 * (velocity * (erf(ratio) + 1) +
        c.most_probable_velocity / √π * exp(-(ratio)^2)) * density
    c.number_flux = mass_flux / (species.mass * species.weighting)
end

function insert_particles!(particles, mesh, time_step)
    ic = mesh.inflow_condition
    num_new_particles = stochastic_round(
        ic.number_flux * mesh.length[2] * time_step
    )
    # TODO This does not need to be threaded...
    for i in eachindex(particles.position)
        particles.inside[i] && continue # TODO this may be quite slow :D

        particles.position[i] = Point2{Float64}(0, rand() * mesh.length[2])
        particles.velocity[i] =
            sample_inflow_velocity(ic.most_probable_velocity, ic.velocity)
        particles.index[i] = index(particles.position[i], mesh)
        particles.inside[i] = true

        # Move back for a fraction of a time step to avoid particle clumping together
        particles.position[i] -= rand() * time_step * Vec2{Float64}(particles.velocity[i])

        num_new_particles -= 1
        num_new_particles <= 0 && break
    end
end