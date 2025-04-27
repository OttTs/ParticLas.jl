function init_gui(lang, path)
    include(path * "languages/" * lang * ".jl")

    gui = GUI()
    gui.resolution = (
        GLFW.GetVideoMode(GLFW.GetPrimaryMonitor()).width,
        GLFW.GetVideoMode(GLFW.GetPrimaryMonitor()).height
    )

    scene = GLMakie.Scene(size=gui.resolution, backgroundcolor=BACKGROUND_COLOR)
    GLMakie.campixel!(scene)

    colorrange, walls = create_display(scene, gui;
        position=(BORDER_WIDTH, BORDER_WIDTH),
        size=gui.resolution .- (3 * BORDER_WIDTH + MENU_WIDTH, 2 * BORDER_WIDTH)
    )

    create_menu(scene, gui, path, colorrange, walls; # display_size, path
        position=(gui.resolution[1] - BORDER_WIDTH - MENU_WIDTH, BORDER_WIDTH),
        size=(MENU_WIDTH, gui.resolution[2] - 2 * BORDER_WIDTH)
    )

    gui.screen = GLMakie.Screen(scene, start_renderloop=false, focus_on_show=true)
    GLFW.make_fullscreen!(gui.screen.glscreen)
    GLFW.SwapInterval(1) # No VSync: 0

    return gui
end

function create_display(scene, gui; position, size)
    display_scene = GLMakie.Scene(scene;
        viewport=GLMakie.Rect(position..., size...),
        backgroundcolor=DISPLAY_BACKGROUND_COLOR,
        clear=true
    )
    GLMakie.campixel!(display_scene)

    colorrange = Observable{NTuple{2, Float32}}((NaN32, NaN32))
    GLMakie.heatmap!(display_scene,
        collect(range(1, size[1], length=NUM_CELLS[1])),
        collect(range(1, size[2], length=NUM_CELLS[2])),
        gui.mesh_values;
        interpolate = true,
        colormap = :afmhot,
        colorrange,
        visible = GLMakie.@lift($(gui.plot_type) != :particles)
    )
    GLMakie.scatter!(display_scene, gui.particle_points;
        marker = GLMakie.FastPixel(),
        markersize = 4,
        color = :black,
        visible = GLMakie.@lift($(gui.plot_type) == :particles)
    )
    walls = Observable{Vector{Point2f}}(Point2f[])
    GLMakie.lines!(display_scene, walls; linewidth = 2, color = WALLS_COLOR)
    box(display_scene, (0, 0), size, :transparent)
    setup_drawing_listener(display_scene, gui, walls)

    return colorrange, walls
end

function create_menu(scene, gui, path, colorrange, walls; position, size)
    box(scene, position, size, MENU_BACKGROUND_COLOR)

    # Create a GridLayout for the settings
    bbox = GLMakie.Rect(position..., size...)
    layout = GLMakie.GridLayout(scene; bbox = bbox, valign = :top)
    layout.parent = scene
    GLMakie.colsize!(layout, 1, GLMakie.Fixed(size[1] - 2 * SETTINGS_BORDER_WIDTH))

    btn = close_button(scene, bbox)
    GLMakie.on(btn.clicks) do _
        gui.terminate = true
    end

    gl_row = 1

    # ---------------------------------------------------------------------------------------------------
    # Add logos
    x_mid = position[1] + size[1] ÷ 2
    y_pos_logo = position[2] + size[2] - BORDER_WIDTH - 40
    image(scene, path * "logos/irs.png", (x_mid - 125, y_pos_logo), 70)
    image(scene, path * "logos/piclas.png", (x_mid + 125, y_pos_logo), 60)
    image(scene, path * "logos/particlas.png", (x_mid, y_pos_logo), 100)
    # Create a box around the logos so that the other items in the GridLayout are below it
    GLMakie.Box(layout[gl_row,:], color=:transparent, strokewidth=0, height=100 + BORDER_WIDTH)
    gl_row += 1

    # ---------------------------------------------------------------------------------------------------
    # Inflow sliders
    label(layout[gl_row, :], LANG_INFLOW_CONDITIONS)
    gl_row += 1
    sg = slidergrid(layout[gl_row, :];
        labels = (LANG_ALTITUDE, LANG_VELOCITY),
        ranges = (MIN_ALTITUDE:MAX_ALTITUDE, MIN_VELOCITY:MAX_VELOCITY),
        startvalues = (DEFAULT_ALTITUDE, DEFAULT_VELOCITY))
    gl_row += 1

    # Listeners
    GLMakie.on(sg.sliders[1].value) do altitude
        gui.inflow_density = 1.225 * exp(-0.11856 * altitude)
        colorrange[] = get_colorrange(gui)
    end

    GLMakie.on(sg.sliders[2].value) do velocity
        gui.inflow_velocity = velocity
        colorrange[] = get_colorrange(gui)
    end

    # ---------------------------------------------------------------------------------------------------
    # Wall stuff
    label(layout[gl_row, :], LANG_WALL_INTERACTION)
    gl_row += 1
    layout[gl_row, :], sl = slider(layout[gl_row, :],
        0:0.01:1,
        DEFAULT_ACCOMODATION_COEFFICIENT,
        (LANG_SPECULAR, LANG_DIFFUSE))
    gl_row += 1
    layout[gl_row, :], tg = toggle(layout[gl_row, :], LANG_COLLISIONS)
    gl_row += 1

    # Listeners
    GLMakie.on(sl.value) do coefficient
        gui.accomodation_coefficient = coefficient
    end

    GLMakie.on(tg.active) do active
        gui.do_collisions = active
    end

    # ---------------------------------------------------------------------------------------------------
    # Display options
    label(layout[gl_row, :], LANG_PLOTTING)
    gl_row += 1
    layout[gl_row, :], mn = menu(layout[gl_row, :], LANG_MENU_OPTIONS, LANG_DISPLAY)
    gl_row += 1

    # Listeners
    GLMakie.on(mn.selection) do _
        gui.plot_type[] = (:particles, :ρ, :u, :T)[mn.i_selected[]]
        colorrange[] = get_colorrange(gui)
    end

    # ---------------------------------------------------------------------------------------------------
    # Object buttons
    label(layout[gl_row, :], LANG_SHAPES)
    gl_row += 1
    layout[gl_row, :] = bg = GLMakie.GridLayout(tellwidth=false)
    for row in 1:2, col in 1:2
        bg[row, col] = btn = button(layout[gl_row,:],
            LANG_SHAPE_LABELS[row, col];
            width=Int(MENU_WIDTH / 2 - 50))

        GLMakie.on(btn.clicks) do _
            # TODO...
            include(path * "examples/" * SHAPE_FILES[row,col])
            for i in eachindex(pts)
                # TODO scaling
                #push!(walls[], pt .* display_size ./ MESH_LENGTH)
                push!(gui.new_walls, (pts[i], pts[i % length(pts) + 1]))
            end
            push!(walls[], Point2f(NaN))
            notify(walls)
            # append!(gui.new_walls, pts) # TODO
        end

    end
    gl_row += 1

    # ---------------------------------------------------------------------------------------------------
    # Buttons
    gl_row += 1
    btn1 = button(layout[gl_row, :], LANG_REMOVE_WALLS)
    gl_row += 1
    btn2 = button(layout[gl_row, :], LANG_REMOVE_PARTICLES)
    gl_row += 1
    button_label = GLMakie.Observable("Play")
    btn3 = button(layout[gl_row, :], button_label)
    gl_row += 1

    # Listeners
    GLMakie.on(btn1.clicks) do _
        gui.delete_walls = true
        empty!(gui.wall_points[])
        notify(gui.wall_points)
    end

    GLMakie.on(btn2.clicks) do _
        gui.delete_particles = true
    end

    GLMakie.on(btn3.clicks) do _
        gui.pause = !gui.pause
        button_label[] = gui.pause ? "Play" : "Pause"
    end

    # ---------------------------------------------------------------------------------------------------
    # Footer
    gl_row += 1
    GLMakie.Label(layout[gl_row, :],
        "© Tobias Ott, Numerical Modeling and Simulation, Institute of Space Systems, University of Stuttgart",
        fontsize = 8,
        halign=:center
    )
end

function get_colorrange(gui)
    if gui.plot_type[] == :ρ
        return (0, 5 * gui.inflow_density)
    elseif gui.plot_type[] == :u
        return (0, gui.inflow_velocity)
    elseif gui.plot_type[] == :T
        return (0, MASS * gui.inflow_velocity^2 / (3BOLTZMANN_CONST) + INFLOW_TEMPERATURE)
    end
    return (NaN32, NaN32)
end