

function worker_thread_loop(id)


    while !terminate
        # 1. Movement step and calculate local moments for collision step
        insert_particles!(particles, mesh, parameters)
        movement_step!(particles, mesh, parameters)

        calculate_moments!()

        # 2. Synchronize and calculate local portion of mesh variables
        synchronize(workers_barrier, id)

        calculate_mesh_variables!()

        # 4. Synchronize and do collision step + calculate moments for conservation
        synchronize(workers_barrier, id)

        collision_step()
        calculate_moments!()

        # 5. Synchronize and do conservation step
        synchronize(workers_barrier, id)

        conseration_step!()


        # Send requested data to GUI
        isrequested(particle_channel) && senddata!(particle_container, id)
        isrequested(density_channel) && senddata!(field_container, mesh, id)
        isrequested(velocity_channel)
        isrequested(temperature_channel)


        # Wait for data from GUI
        if id == 1
            settings = take!(settings_channel)

            waitfor(settings_container)

            # Use data from container
            # Copy data and request new data
            # TODO instead of copy, use it!
            copydata!(settings_container)
            #=
            - pause
            - reset (particles & walls)
            - terminate
            - do_collisions
            - accomodation_coefficient
            - Inflow condition
            - Walls
            =#


            requestdata(settings_container)
        end

        synchronize(simulation_barrier)

    end
end