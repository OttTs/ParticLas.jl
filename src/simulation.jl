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