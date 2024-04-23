include("simulation/particles.jl")
include("simulation/statistics.jl")



function simulation_thread(thread_id)
    while !terminate
        if !pause
            # Local particles only!
            insert_particles(particles, inflow, mesh, time_step)
            movement_step!(particles, time_step, mesh, wall_condition)
            # TODO send particle data here
            deposit!(particles, mesh, thread_id)
            settings.plot_type == :particles && send_particle_data!(particles, settings)
            synchronize!(barrier)

            # TODO send mesh data during collision step
            collision_step!(particles, time_step, species, mesh, thread_id, settings)
        end
        reset_walls && delete_walls!(mesh, thread_id)
        synchronize!(barrier)
        thread_id == 1 && receive_settings()
        synchronize!(barrier)
        reset_particles && clear!(particles)
    end
end

#=
This deposition is not like the one in PICLas.
Here, the particles are added to the list of particles in each cell.
This is done for the collision step, where each cell needs to know its particles.
=#
function deposit!(particles, mesh, thread_id)
    for particle in particles
        index = get_index(particle.position, mesh)
        particles_in_cell = local_list(mesh.cells[index].particles, thread_id)
        push!(particles_in_cell, particle)
    end
end