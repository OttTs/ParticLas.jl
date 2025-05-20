function renderloop(gui, channel)
    while !gui.terminate[]
        starttime = frametime()

        reset!(gui)

        # Get new events and render new frame
        #@sync begin
            GLMakie.pollevents(gui.screen, GLMakie.Makie.RegularRenderTick) # TODO ...
            GLMakie.render_frame(gui.screen)
            GLFW.SwapBuffers(gui.screen.glscreen)
        #end

        # Send and receive the data
        send!(gui, data(channel, 1))
        t1 = frametime()
        swap!(channel, 1)
        t2 = frametime()
        update!(gui, data(channel, 1))
        #yield() # We need to yield to allow other tasks to run! (DO WE?)

        # TODO Delete (Only debug)
        open("gui.time", "w") do io
            write(io, "$(round(frametime() - t2 + t1 - starttime; digits=2))")
        end

        # Wait for the rest of the frame
        #while frametime() - starttime < 1; end
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
            xₚ[i] = xₚ[i] .* gui.display_scaling
        end
        gui.particle_points[] = xₚ
        notify(gui.particle_points)
    else
        gui.mesh_values[] = data.mesh_values
    end
end