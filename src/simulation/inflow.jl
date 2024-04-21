#=
Each thread needs to insert particles at the inflow boundary in every time step.
For this, a random point at the inflow wall is chosen and a particle velocity is sampled.
=#

struct InflowCondition
    number_flux::Float64 # per thread!
    velocity::Float64
    most_probable_velocity::Float64
end

function insert_particles(
    particles::ParticleData, 
    inflow::InflowCondition,
    mesh::Mesh, 
    time_step::Number
)
    num_new_particles = stochastic_round(inflow.number_flux * mesh.length[2] * time_step)

    # Add new particles
    for _ in 1:num_new_particles
        isfull(particles) && return nothing

        position = Point2{Float64}(0, rand() * mesh.length[2])
        velocity = sample_inflow_velocity(inflow.velocity, inflow.most_probable_velocity)

        # Move back for a fraction of a time step to avoid particle clumping together
        position = position - rand() * time_step * Point2{Float64}(velocity)

        add_particle!(particles, position, velocity, index(position, mesh))
    end
end

function sample_inflow_velocity(velocity, most_probable_velocity)
    zs = samplezs(velocity / most_probable_velocity)
    return Point3{Float64}( 
        velocity - zs * most_probable_velocity,
        √0.5 * most_probable_velocity * randn(),
        √0.5 * most_probable_velocity * randn()
    )
end

function stochastic_round(x)
    # Round up or down to get x as the mean
    if rand() > x - floor(x)
        return floor(Int64, x)
    else
        return ceil(Int64, x)
    end
end

function samplezs(a::Number)
    # Samples the random variable zs with a given speed ratio a
    # See "Garcia and Wagner - 2006 - Generation of the Maxwellian inflow distribution"
    if a < -0.4
        z = 0.5*(a - √(a^2+2))
        β = a - (1 - a) * (a - z)
        while true
            if exp(-β^2) / (exp(-β^2) + 2 * (a - z) * (a - β) * exp(-z^2)) > rand()
                zs = -√(β^2 - log(rand()))
                (zs - a) / zs > rand() && return zs
            else
                zs = β + (a - β) * rand()
                (a - zs) / (a - z) * exp(z^2 - zs^2) > rand() && return zs
            end
        end
    elseif a < 0
        while true
            zs = -√(a^2 - log(rand()))
            (zs - a) / zs > rand() && return zs
        end
    elseif a < 1.3
        while true
            u = rand()
            a * √π / (a * √π + 1 + a^2) > u && return -1/√2 * abs(randn())
            (a * √π + 1) / (a * √π + 1 + a^2) > u && return -√(-log(rand()))
            zs = (1 - √rand()) * a
            exp(-zs^2) > rand() && return zs
        end
    else # a > 1.3
        while true
            if 1 / (2 * a * √π + 1) > rand()
                zs = -√(-log(rand()))
            else
                zs = 1 / √2 * randn()
            end
            (a - zs) / a > rand() && return zs
        end
    end
end