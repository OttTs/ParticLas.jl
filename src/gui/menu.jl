#=
Menu

For the menu, only a Box is drawn and NO scene is created.
The close button and the logos are drawn on top of the Box.
The menu items are drawn in a GridLayout.

Data for the simulation is directly updated in the channel.
=#
function draw_menu(scene, variable_to_plot, color_range, walls, channel; position, size, scaling, path)
    # 1. Draw the background box
    box(scene, position, size, BLUE_VERY_LIGHT)

    # 2. Create a GridLayout and add the items
    layout = GLMakie.GridLayout(; bbox = GLMakie.Rect(position..., size...), valign = :top)
    layout.parent = scene
    GLMakie.colsize!(layout, 1, GLMakie.Fixed(size[1] - 2 * SETTINGS_BORDER_WIDTH))

    nrows = 0

    # ---------------------------------------------------------------------------------------------------
    # Close button
    btn_size = 24
    btn = GLMakie.Button(scene,
        bbox=GLMakie.Rect((position .+ size .- btn_size .- 10)...,btn_size, btn_size),
        label = "✕",
        height=btn_size,
        width=btn_size,
        cornerradius=btn_size,
        buttoncolor=RGBf(0.2, 0.2, 0.2),
        buttoncolor_hover=RGBf(0.8, 0.2, 0.2),
        buttoncolor_active=RGBf(0.5, 0.2, 0.2),
        labelcolor=RGBf(0.8,0.8,0.8),
        labelcolor_active=RGBf(0.8,0.8,0.8),
        labelcolor_hover=RGBf(0.8,0.8,0.8),
        fontsize=(btn_size*2)÷3,
        strokecolor=BLUE_VERY_LIGHT,
        strokewidth=1
    )

    GLMakie.on(btn.clicks) do _
        data(channel,1).terminate = true
        swap!(channel,1) # We need to tell the simulation to stop
        screen = GLMakie.Makie.getscreen(scene)
        GLMakie.stop_renderloop!(screen)
        GLFW.make_windowed!(screen.glscreen)
        close(screen; reuse=false)
    end

    # -----------------------------------------------------------------------------------------------------------------------
    # Add logos
    x_mid = position[1] + size[1] ÷ 2
    y_pos_logo = position[2] + size[2] - BORDER_WIDTH - 40
    image(scene, path * "logos/irs.png", (x_mid - 125, y_pos_logo), 70)
    image(scene, path * "logos/piclas.png", (x_mid + 125, y_pos_logo), 60)
    image(scene, path * "logos/particlas.png", (x_mid, y_pos_logo), 100)
    # Create a box around the logos so that the other items in the GridLayout are below it
    GLMakie.Box(layout[nrows+=1,:], color=:transparent, strokewidth=0, height=100 + BORDER_WIDTH)

    # -----------------------------------------------------------------------------------------------------------------------
    # Inflow section
    GLMakie.Label(layout[nrows+=1, :], LANG_INFLOW_CONDITIONS; fontsize = SECTION_FONTSIZE)
    sg = GLMakie.SliderGrid(layout[nrows+=1, :],
        (label=LANG_ALTITUDE, range=(MIN_ALTITUDE:MAX_ALTITUDE), startvalue=DEFAULT_ALTITUDE, format = " "),
        (label=LANG_VELOCITY, range=(MIN_VELOCITY:MAX_VELOCITY), startvalue=DEFAULT_VELOCITY, format = " "),
    )

    tg = GLMakie.Toggle(layout[nrows+=1, :],active=true)
    layout[nrows, :] = GLMakie.hgrid!(GLMakie.Label(layout[nrows, :], LANG_COLLISIONS),tg,halign=:left)

    # Listeners
    GLMakie.on(sg.sliders[1].value) do altitude
        data(channel,1).inflow_density = 1.225 * exp(-0.11856 * altitude)
        color_range[] = get_colorrange(variable_to_plot, data(channel,1).inflow_density, data(channel,1).inflow_velocity)
    end

    GLMakie.on(sg.sliders[2].value) do velocity
        data(channel,1).inflow_velocity = velocity
        color_range[] = get_colorrange(variable_to_plot, data(channel,1).inflow_density, data(channel,1).inflow_velocity)
    end

    GLMakie.on(tg.active) do active
        data(channel,1).do_collisions = active
    end

    # -----------------------------------------------------------------------------------------------------------------------
    # Wall section
    GLMakie.Label(layout[nrows+=1, :], LANG_WALL_INTERACTION; fontsize = SECTION_FONTSIZE)
    # TODO How to do DEFAULT_ACCOMODATION_COEFFICIENT?
    sl = GLMakie.Slider(layout[nrows+=1,:],range=0:0.01:1)
    layout[nrows,:] = GLMakie.hgrid!(
        GLMakie.Label(layout[nrows,:], LANG_SPECULAR),
        sl,
        GLMakie.Label(layout[nrows,:], LANG_DIFFUSE))

    # Listeners
    GLMakie.on(sl.value) do coefficient
        data(channel,1).accomodation_coefficient = coefficient
    end

    # -----------------------------------------------------------------------------------------------------------------------
    # Display section
    GLMakie.Label(layout[nrows+=1, :], LANG_PLOTTING; fontsize = SECTION_FONTSIZE)
    mn = GLMakie.Menu(layout[nrows+=1, :],options=LANG_MENU_OPTIONS,default=LANG_MENU_OPTIONS[1])
    layout[nrows, :] = GLMakie.hgrid!(GLMakie.Label(layout[nrows, :], LANG_DISPLAY), mn)

    # Listeners
    GLMakie.on(mn.selection) do _
        variable_to_plot[] = (:particles, :ρ, :u, :T)[mn.i_selected[]]
        color_range[] = get_colorrange(variable_to_plot, data(channel,1).inflow_density, data(channel,1).inflow_velocity)
    end

    # -----------------------------------------------------------------------------------------------------------------------
    # Object section
    GLMakie.Label(layout[nrows+=1, :], LANG_SHAPES; fontsize = SECTION_FONTSIZE)
    layout[nrows+=1, :] = bg = GLMakie.GridLayout(tellwidth=false)
    for row in 1:2, col in 1:2
        # Create button
        bg[row, col] = btn = GLMakie.Button(layout[nrows,:];
            label=LANG_SHAPE_LABELS[row, col],
            width=Int(MENU_WIDTH / 2 - 50))

        # Add Listener
        GLMakie.on(btn.clicks) do _
            include(path * "examples/" * SHAPE_FILES[row,col])
            for pt in pts
                push!(walls[], pt .* scaling)
            end
            push!(walls[], Point2f(NaN))
            notify(walls)
            for i in 2:length(pts)
                push!(data(channel, 1).new_walls, (pts[i-1], pts[i]))
            end
        end
    end

    # -----------------------------------------------------------------------------------------------------------------------
    # Buttons
    nrows += 1 # To the bottom of the layout
    delete_walls_button = GLMakie.Button(layout[nrows+=1, :], label=LANG_REMOVE_WALLS)
    delete_particles_button = GLMakie.Button(layout[nrows+=1, :], label=LANG_REMOVE_PARTICLES)
    play_button_label = GLMakie.Observable("Play")
    play_button = GLMakie.Button(layout[nrows+=1, :], label=play_button_label)

    # Listeners
    GLMakie.on(delete_walls_button.clicks) do _
        data(channel,1).delete_walls = true
        empty!(walls[])
        notify(walls)
    end

    GLMakie.on(delete_particles_button.clicks) do _
        data(channel,1).delete_particles = true
    end

    GLMakie.on(play_button.clicks) do _
        data(channel,1).pause = !data(channel,1).pause
        play_button_label[] = data(channel,1).pause ? "Play" : "Pause"
    end

    # -----------------------------------------------------------------------------------------------------------------------
    # Footer
    GLMakie.Label(layout[nrows+=2, :],
        "© Tobias Ott, Numerical Modeling and Simulation, Institute of Space Systems, University of Stuttgart",
        fontsize = 8,
        halign=:center
    )
end

#=
Helper functions to create the menu items
=#
function image(scene, img_path, center_position, height)
    file = GLMakie.load(img_path)
    hsize = (round(Int, GLMakie.size(file)[2]/GLMakie.size(file)[1] * height), height).÷2
    img = GLMakie.image!(scene,
        center_position[1].+(-hsize[1],hsize[1]),
        center_position[2].+(-hsize[2],hsize[2]),
        GLMakie.rotr90(file)
    )
    GLMakie.translate!(img, (0, 0, 1)) # foreground
end


function get_colorrange(variable_to_plot, inflow_density, inflow_velocity)
    if variable_to_plot[] == :ρ
        return (0, 5 * inflow_density)
    elseif variable_to_plot[] == :u
        return (0, inflow_velocity)
    elseif variable_to_plot[] == :T
        return (0, MASS * inflow_velocity^2 / (3BOLTZMANN_CONST) + INFLOW_TEMPERATURE)
    end
    return (NaN32, NaN32)
end