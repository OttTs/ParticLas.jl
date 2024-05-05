function renderloop(gui_data, gui_channel, sim_channel)
    while !gui_data.terminate[]
        starttime = frametime()

        # Reset the data
        gui_data.new_wall = (Point2{Float64}(NaN), Point2{Float64}(NaN))
        gui_data.delete_particles = false
        gui_data.delete_walls = false

        # Get new evenets and render new frame
        gui_data.timing_data.gui_start = frametime()
        GLMakie.pollevents(gui_data.screen)
        gui_data.timing_data.pollevents = frametime()
        GLMakie.render_frame(gui_data.screen)
        GLFW.SwapBuffers(gui_data.screen.glscreen)
        gui_data.timing_data.rendering = frametime()

        # Send the gui data
        copy_data!(sender_data(gui_channel), gui_data)
        send!(gui_channel)

        # Receive the simulation data for the new time step
        receive!(sim_channel)
        gui_data.timing_data.communication = frametime()
        if !gui_data.pause
            if gui_data.plot_type == :particles
                particle_positions = data(sim_channel).particle_positions
                for i in eachindex(particle_positions)
                    particle_positions[i] = particle_positions[i] .* gui_data.point_scaling
                end
                gui_data.particle_points[] = particle_positions
            else
                gui_data.mesh_values[] = data(sim_channel).mesh_values
            end

            # Timing
            for field in [:sim_start, :insertion, :movement, :deposition, :collision]
                setfield!(gui_data.timing_data, field, 
                    getfield(data(sim_channel).timing_data, field)
                )
            end
        end
        gui_data.timing_data.copy = frametime()

        # Print debug output
        print_console_output(gui_data.timing_data)

        # Wait for the rest of the frame
        dur = (1 + starttime - frametime()) / FPS
        dur > 0.01 && sleep(0.8 * dur)
        while frametime() - starttime < 1; end
    end
    GLFW.make_windowed!(gui_data.screen.glscreen)
    GLFW.close(gui_data.screen; reuse=false)
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
end

function print_console_output(data)
    com = data.communication - data.rendering
    msg = @sprintf "\u1b[15F
        ____________________________________________
       | Wait for simulation..........%6.2f frames |
    " com

    pol = data.pollevents - data.gui_start
    rnd = data.rendering - data.pollevents
    cpy = data.copy - data.communication
    msg *= @sprintf "   |____________________________________________|
       |                    Visu                    |
       | Pollevents...................%6.2f frames |
       | Rendering....................%6.2f frames |
       | Copy new data................%6.2f frames |
    " pol rnd cpy

    ins = data.insertion - data.sim_start
    mov = data.movement - data.insertion
    dep = data.deposition - data.movement
    col = data.collision - data.deposition
    msg *= @sprintf "   | ___________________________________________|
       |                 Simulation                 |
       | Insertion....................%6.2f frames |
       | Movement.....................%6.2f frames |
       | Deposition...................%6.2f frames |
       | Collision....................%6.2f frames |
        ‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾
    " ins mov dep col

    print(msg)
end