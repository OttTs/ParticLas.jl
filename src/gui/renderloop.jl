function renderloop(gui, channel)
    while !gui.terminate[]
        starttime = frametime()

        reset!(gui)

        # Get new events and render new frame
        GLMakie.pollevents(gui.screen, GLMakie.Makie.RegularRenderTick) # TODO ...
        GLMakie.render_frame(gui.screen)
        GLFW.SwapBuffers(gui.screen.glscreen)

        # Send and receive the data
        send!(gui, data(channel, 1))
        #swap!(channel, 1)
        update!(gui, data(channel, 1))
        yield() # We need to yield to allow other tasks to run! (DO WE?)

        # Wait for the rest of the frame
        while frametime() - starttime < 1; end
    end
end

function reset!(gui::GUI)
    gui.delete_particles = false
    gui.delete_walls = false
    empty!(gui.new_walls)
end

function send!(gui::GUI, data)
    fields = (
        :terminate, :pause,
        :delete_walls, :delete_particles,
        :do_collisions,
        :inflow_density, :inflow_velocity,
        :accomodation_coefficient
    )
    data.plot_type = gui.plot_type[]
    for i in fields
        setfield!(data, i, getfield(gui, i))
    end

    empty!(data.new_walls)
    for wall in gui.new_walls
        push!(data.new_walls, wall)
    end
end

function update!(gui::GUI, data)
    if gui.plot_type[] == :particles
        xₚ = data.particle_positions
        for i in eachindex(xₚ)
            xₚ[i] = xₚ[i] #.* gui.point_scaling # TODO
        end
        gui.particle_points[] = xₚ
    else
        gui.mesh_values[] = data.mesh_values
    end
end