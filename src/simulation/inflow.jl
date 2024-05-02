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

function insert_particles(particles, mesh, inflow, time_step)
    num_new_particles = stochastic_round(
        inflow.number_flux * mesh.length[2] * time_step / Threads.nthreads(:default)
    )
    for _ in 1:num_new_particles
        isfull(particles) && break

        p = add!(particles)
        p.position = Point2{Float64}(0, rand() * mesh.length[2])
        p.velocity = sample_inflow_velocity(inflow.most_probable_velocity, inflow.velocity)

        # Move back for a fraction of a time step to avoid particle clumping together
        p.position = p.position - rand() * time_step * Vec2{Float64}(p.velocity)
    end
end