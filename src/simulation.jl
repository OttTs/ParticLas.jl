include("simulation/species.jl")
include("simulation/particles.jl")
include("simulation/statistics.jl")
include("simulation/mesh.jl")
include("simulation/collision_operator.jl")
include("simulation/inflow.jl")
include("simulation/movement.jl")

const BOLTZMANN_CONST = 1.380649E-23

function simulation_thread(
    particles,
    species,
    inflow,
    mesh,
    time_step,
    thread_id,
    barrier,
    settings,
    plotting_data
)
    while !data(settings).terminate
        if !data(settings).pause
            # Local particles only!
            insert_particles(particles, inflow, mesh, time_step)
            movement_step!(particles, time_step, mesh, data(settings).wall_condition)
            deposit!(particles, mesh, thread_id)
            send_particle_data!(particles, plotting_data)
            synchronize!(barrier)

            collision_step!(
                mesh,
                time_step,
                species,
                thread_id,
                #plotting_data # Send data during collision # TODO
            )
        end
        !data(settings).delete_walls && delete_walls!(mesh, thread_id)
        synchronize!(barrier)
        thread_id == 1 && receive_settings_data!(settings)


        # Add wall and set inflow?
        synchronize!(barrier)

        !data(settings).delete_particles && clear!(particles)
    end
end

#=
This deposition is not like the one in PICLas.
Here, the particles are added to the list of particles in each cell.
This is done for the collision step, where each cell needs to know its particles.
=#
function deposit!(particles, mesh, thread_id)
    delete_particles!(mesh, thread_id)
    for particle in particles
        index = get_index(particle.position, mesh)
        particles_in_cell = local_list(mesh.cells[index].particles, thread_id)
        push!(particles_in_cell, particle)
    end
end