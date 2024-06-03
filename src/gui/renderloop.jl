function renderloop(gui_data, channel)
    while !gui_data.terminate[]
        starttime = frametime()

        reset_data!(gui_data)

        # Get new events and render new frame
        GLMakie.pollevents(gui_data.screen)
        GLMakie.render_frame(gui_data.screen)
        GLFW.SwapBuffers(gui_data.screen.glscreen)

        # Send and receive the data
        copy_data!(guidata(channel), gui_data)
        swap!(channel) # TODO ? swap_blocking!(channel, 1)
        set_new_data!(gui_data, guidata(channel))
        yield() # We need to yield to allow other tasks to run!

        # Wait for the rest of the frame
        while frametime() - starttime < 1; end
    end
end

function reset_data!(gui_data)
    gui_data.new_wall = (Point2{Float64}(NaN), Point2{Float64}(NaN))
    gui_data.delete_particles = false
    gui_data.delete_walls = false
    empty!(gui_data.object_points)
end

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
    copy!(channel_data.object_points, gui_data.object_points)
end

function set_new_data!(gui_data::GUIData, channel_data)
    if gui_data.plot_type == :particles
        particle_positions = channel_data.particle_positions
        for i in eachindex(particle_positions)
            particle_positions[i] = particle_positions[i] .* gui_data.point_scaling
        end
        gui_data.particle_points[] = particle_positions
    else
        gui_data.mesh_values[] = channel_data.mesh_values
    end
end