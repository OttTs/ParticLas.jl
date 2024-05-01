function renderloop(gui_data, gui_channel, sim_channel)
    while !gui_data.terminate[]
        starttime = frametime(FPS)

        # Reset the data
        gui_data.new_wall = (Point2{Float64}(NaN), Point2{Float64}(NaN))
        gui_data.delete_particles = false
        gui_data.delete_walls = false


        # Get new evenets and render new frame
        GLMakie.pollevents(gui_data.screen)
        GLMakie.render_frame(gui_data.screen)
        GLFW.SwapBuffers(gui_data.screen.glscreen)


        # Send the gui data
        copy_data!(sender_data(gui_channel), gui_data)
        send!(gui_channel)

        # Receive the simulation data for the new time step
        receive!(sim_channel)
        if gui_data.plot_type == :particles
            data(sim_channel).particle_positions .*= gui_data.point_scaling
            gui_data.particle_points[] = data(sim_channel).particle_positions
        else
            gui_data.mesh_values[] = data(sim_channel).mesh_values
        end

        # Wait for the rest of the frame
        dur = (1 + starttime - frametime(FPS)) / FPS
        dur > 0.01 && sleep(0.8 * dur)
        while frametime(FPS) - starttime < 1; end
    end
    GLFW.make_windowed!(gui_data.screen.glscreen)
    close(gui_data.screen; reuse=false)
end

frametime(fps) = (time_ns() / 1e9) * fps

function copy_data!(channel_data, gui_data::GUIData)
    fields = (
        :terminate, 
        :pause, 
        :plot_type, 
        :inflow_altitude, 
        :inflow_velocity, 
        :new_wall, 
        :accomodation_coefficient, 
        :delete_walls, 
        :delete_particles
    )
    for i in fields
        setfield!(channel_data, i, getfield(gui_data, i))
    end
end
