function renderloop(gui_data, channel)
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

        # Send and receive the data
        copy_data!(guidata(channel), gui_data)
        swap!(channel)
        gui_data.timing_data.communication = frametime()
        if !gui_data.pause
            if gui_data.plot_type == :particles
                particle_positions = guidata(channel).particle_positions
                for i in eachindex(particle_positions)
                    particle_positions[i] = particle_positions[i] .* gui_data.point_scaling
                end
                gui_data.particle_points[] = particle_positions
            else
                gui_data.mesh_values[] = guidata(channel).mesh_values
            end

            # Timing
            for field in [:sim_start, :movement, :relax_parameters, :relax,
                :conservation_parameters, :conservation]
                setfield!(gui_data.timing_data, field,
                    getfield(guidata(channel).timing_data, field)
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
    msg = @sprintf "\u1b[16F
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


    mov = data.movement - data.sim_start
    rel_par = data.relax_parameters - data.movement
    rel = data.relax - data.relax_parameters
    con_par = data.conservation_parameters - data.relax
    con = data.conservation - data.conservation_parameters
    msg *= @sprintf "   | ___________________________________________|
       |                 Simulation                 |
       | Movement.....................%6.2f frames |
       | Relaxation Params............%6.2f frames |
       | Relaxation...................%6.2f frames |
       | Conservation Params..........%6.2f frames |
       | Conservation ................%6.2f frames |
        ‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾
    " mov rel_par rel con_par con


    print(msg)
end