include("simulation/particles.jl")
include("simulation/statistics.jl")



function simulation_thread(thread_id)
    while !terminate

        if !pause
            insert_particles!()

            movement_step!()

            deposit!()

            synchronize!()

            collision_step!()
        end

        # TODO
        # send output data
        #  -> This is done by each thread in movement_step / collision step!

        # Receive is actually:
        # thread_id == 1 && receive_settings()
        # synchronize!()

        # reset_particles, reset_walls?
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