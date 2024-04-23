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
        velocity = sample_inflow_velocity(inflow.most_probable_velocity, inflow.velocity)

        # Move back for a fraction of a time step to avoid particle clumping together
        position = position - rand() * time_step * Point2{Float64}(velocity)

        add_particle!(particles, position, velocity, index(position, mesh))
    end
end