function setup_gui(particlas_path)
    gui_data = GUIData()

    # Get Window size and create Scene
    window_size = (
        GLFW.GetVideoMode(GLFW.GetPrimaryMonitor()).width,
        GLFW.GetVideoMode(GLFW.GetPrimaryMonitor()).height
    )
    display_size = window_size .- (3, 2) .* BORDER_WIDTH .- (MENU_WIDTH, 0)
    gui_data.point_scaling = display_size ./ MESH_LENGTH

    scene = GLMakie.Scene(size=window_size, backgroundcolor=BACKGROUND_COLOR)
    GLMakie.campixel!(scene)

    setup_display(scene, gui_data;
        pos=BORDER_WIDTH .* (1, 1),
        size=display_size
    )

    setup_menu(scene, gui_data;
        pos=(display_size[1], 0) .+ BORDER_WIDTH .* (2, 1),
        size=(MENU_WIDTH, display_size[2]),
        display_size,
        particlas_path
    )

    gui_data.screen = GLMakie.Screen(scene, start_renderloop=false, focus_on_show=true)
    GLFW.make_fullscreen!(gui_data.screen.glscreen)
    GLFW.SwapInterval(1) # No VSync: 0

    return gui_data
end

#=
===========================================================================================
=#

function setup_display(scene, gui_data; pos, size)
    display_scene = GLMakie.Scene(scene,
        viewport=GLMakie.Rect(pos..., size...),
        backgroundcolor=DISPLAY_BACKGROUND_COLOR,
        clear=true
    )
    GLMakie.campixel!(display_scene)

    # 1. Heatmap plot for physical mesh values
    GLMakie.heatmap!(display_scene,
        collect(range(1, size[1], length=NUM_CELLS[1])),
        collect(range(1, size[2], length=NUM_CELLS[2])),
        gui_data.mesh_values;
        interpolate = true,
        colormap = :afmhot,
        visible =  GLMakie.@lift(!$(gui_data.display_particles))
    )

    # 2. Scatter plot for particles
    GLMakie.scatter!(display_scene, gui_data.particle_points;
        marker = GLMakie.FastPixel(),
        markersize = 2,#2,
        color = :black, # TODO color with velocity?
        visible = gui_data.display_particles
    )

    # 3. Lines for walls
    GLMakie.lines!(display_scene, gui_data.wall_points;
        linewidth = 2,
        color = WALLS_COLOR
    )

    # 4. Create rounded edges
    stroke_width = (√8 - 2) * SCENE_CORNER_RADIUS
    GLMakie.Box(display_scene,
        bbox=GLMakie.Rect(0, 0, size...),
        cornerradius=√2 * SCENE_CORNER_RADIUS,
        width=size[1] + stroke_width,
        height=size[2] + stroke_width,
        strokewidth=stroke_width,
        strokecolor=BACKGROUND_COLOR,
        color=:transparent
    )

    # Handle drawing
    drawing = Ref{Bool}(false)
    GLMakie.on(GLMakie.events(display_scene).mouseposition) do p
        p = p .- BORDER_WIDTH
        pressed = GLMakie.ispressed(display_scene, GLMakie.Mouse.left)
        inside = all(0 .< p .< size) # 0 or offset?

        if pressed && inside && drawing[]
            continuedrawing(gui_data, p, size)
        elseif pressed && inside && !drawing[]
            drawing[] = true
            push!(gui_data.wall_points[], p, p)
        elseif drawing[]
            drawing[] = false
            stopdrawing(gui_data, size)
        end
        notify(gui_data.wall_points)
    end
end

function continuedrawing(gui_data, position, display_size)
    gui_data.wall_points[][end] = position
    if norm(gui_data.wall_points[][end] - gui_data.wall_points[][end-1]) > 5
        gui_data.new_wall = (
            gui_data.wall_points[][end-1] ./ display_size .* MESH_LENGTH,
            gui_data.wall_points[][end] ./ display_size .* MESH_LENGTH
        )
        push!(gui_data.wall_points[], position)
    end
end

function stopdrawing(gui_data, display_size)
    gui_data.new_wall = (
        gui_data.wall_points[][end-1] ./ display_size .* MESH_LENGTH,
        gui_data.wall_points[][end] ./ display_size .* MESH_LENGTH
    )
    push!(gui_data.wall_points[], Point2f(NaN))
end

#=
===========================================================================================
=#

function setup_menu(scene, gui_data; pos, size, display_size, particlas_path)
    # Settings Box
    settings_bbox = GLMakie.Rect(pos..., size...)
    GLMakie.Box(scene,
        bbox=settings_bbox,
        cornerradius=SCENE_CORNER_RADIUS,
        width=size[1],
        height=size[2],
        strokewidth=1,
        strokecolor=MENU_BACKGROUND_COLOR,
        color=MENU_BACKGROUND_COLOR
    )

    # Create a GridLayout for the settings
    layout = GLMakie.GridLayout(scene, bbox=settings_bbox, valign = :top)
    layout.parent = scene
    GLMakie.colsize!(layout, 1, GLMakie.Fixed(size[1] - 2 * SETTINGS_BORDER_WIDTH))

    add_close_button!(scene, gui_data, settings_bbox)
    i = add_logo!(scene, settings_bbox, layout, 1; particlas_path)
    i = add_gap!(layout, 10, i)
    i = add_inflow_block!(layout, gui_data, i)
    i = add_gap!(layout, 10, i)
    i = add_wall_block!(layout, gui_data, i)
    i = add_gap!(layout, 10, i)
    i = add_menu_block!(layout, gui_data, i, display_size)
    i = add_object_buttons!(layout, gui_data, i, display_size; particlas_path)
    i = add_buttons!(layout, gui_data, i + 1)
    i = add_gap!(layout, 50, i)

    GLMakie.Label(layout[i,:], "© Tobias Ott, Numerical Modeling and Simulation, Institute of Space Systems, University of Stuttgart",
        fontsize = 8,
        halign=:center
    )
end

# -----------------------------------------------------------------------------------------
function add_close_button!(scene, gui_data, settings_bbox)
    close_button_size = 24
    button_close = GLMakie.Button(scene,
        bbox=GLMakie.Rect(
            (settings_bbox.origin + settings_bbox.widths .- close_button_size .- 10)...,
            close_button_size,
            close_button_size
        ),
        label = "✕",
        height=close_button_size,
        width=close_button_size,
        cornerradius=close_button_size÷2,
        buttoncolor=RGBf(0.2, 0.2, 0.2),
        buttoncolor_hover=RGBf(0.8, 0.2, 0.2),
        buttoncolor_active=RGBf(0.5, 0.2, 0.2),
        labelcolor=RGBf(0.8,0.8,0.8),
        labelcolor_active=RGBf(0.8,0.8,0.8),
        labelcolor_hover=RGBf(0.8,0.8,0.8),
        fontsize=(close_button_size*2)÷3,
        strokecolor=MENU_BACKGROUND_COLOR,
        strokewidth=1
    )

    GLMakie.on(button_close.clicks) do _
        gui_data.terminate = true
    end
end

# -----------------------------------------------------------------------------------------
function add_logo!(scene, settings_bbox, layout, n; particlas_path)
    origin = settings_bbox.origin
    widths = settings_bbox.widths

    # TODO which path?
    # TODO 1. Copy Logos to bin, 2. Path needs to be known here

    logo = GLMakie.load(particlas_path * "logos/irs.png")
    logo_size = (510/397*60, 60)
    img = GLMakie.image!(scene,
        (origin[1] + widths[1]÷2 - 125) .+ (-0.5 * logo_size[1], 0.5 * logo_size[1]),
        origin[2] - BORDER_WIDTH + widths[2] - 10 .+ (-logo_size[2], 0),
        GLMakie.rotr90(logo)
    )
    GLMakie.translate!(img, (0, 0, 1)) # Put it in the foreground

    logo = GLMakie.load(particlas_path * "logos/piclas.png")
    # 1769 x 870
    logo_size = (1769/870*60, 60)
    #logo_size = 60
    img = GLMakie.image!(scene,
        (origin[1] + widths[1]÷2 + 125) .+ (-0.5 * logo_size[1], 0.5 * logo_size[1]),
        origin[2] - BORDER_WIDTH + widths[2] - 20 .+ (-logo_size[2], 0),
        GLMakie.rotr90(logo)
    )
    GLMakie.translate!(img, (0, 0, 1)) # Put it in the foreground

    logo = GLMakie.load(particlas_path * "logos/particlas.png")
    logo_size = 100
    img = GLMakie.image!(scene,
        (origin[1] + widths[1]÷2) .+ (-0.5 * logo_size, 0.5 * logo_size),
        origin[2] - BORDER_WIDTH + widths[2] .+ (-logo_size, 0),
        GLMakie.rotr90(logo)
    )
    GLMakie.translate!(img, (0, 0, 1)) # Put it in the foreground

    # Fix: Offset for Image...
    GLMakie.Box(layout[n,:],
        color=:transparent,
        strokewidth=0,
        height=logo_size+BORDER_WIDTH
        )

    return n + 1
end

# -----------------------------------------------------------------------------------------
function add_inflow_block!(layout, gui_data, n)
    GLMakie.Label(layout[n,:], "Inflow Conditions",
        fontsize = SECTION_FONTSIZE,
        halign=:left
    )

    n += 1

    slidergrid = GLMakie.SliderGrid(layout[n,:],
        (
            label = "Altitude",
            range = MIN_ALTITUDE:MAX_ALTITUDE,
            format = "",
            startvalue = DEFAULT_ALTITUDE,
            linewidth = SLIDER_LINE_WIDTH,
            snap=false,
            color_inactive=SLIDER_COLOR_RIGHT,
            color_active_dimmed=SLIDER_COLOR_LEFT,
            color_active=SLIDER_COLOR_CIRCLE
        ),(
            label = "Velocity",
            range = MIN_VELOCITY:MAX_VELOCITY,
            format = "",
            startvalue = DEFAULT_VELOCITY,
            linewidth = SLIDER_LINE_WIDTH,
            snap=false,
            color_inactive=SLIDER_COLOR_RIGHT,
            color_active_dimmed=SLIDER_COLOR_LEFT,
            color_active=SLIDER_COLOR_CIRCLE
        )
    )
    slidergrid.labels[1].fontsize[] = CONTENT_FONTSIZE
    slidergrid.labels[2].fontsize[] = CONTENT_FONTSIZE

    GLMakie.on(slidergrid.sliders[1].value) do altitude
        gui_data.inflow_altitude = altitude
    end

    GLMakie.on(slidergrid.sliders[2].value) do velocity
        gui_data.inflow_velocity = velocity
    end

    return n + 1
end

# -----------------------------------------------------------------------------------------
function add_wall_block!(layout, gui_data, n)
    GLMakie.Label(layout[n,:], "Wall Interaction",
        fontsize = SECTION_FONTSIZE,
        halign=:left
    )

    n += 1

    accomodation_slider = GLMakie.Slider(layout[n,:],
        range=0:0.01:1,
        startvalue=DEFAULT_ACCOMODATION_COEFFICIENT,
        linewidth = SLIDER_LINE_WIDTH,
        snap=false,
        color_inactive=SLIDER_COLOR_RIGHT,
        color_active_dimmed=SLIDER_COLOR_LEFT,
        color_active=SLIDER_COLOR_CIRCLE
    )
    layout[n,:] = GLMakie.hgrid!(
        GLMakie.Label(layout[n,:], "Specular", fontsize=CONTENT_FONTSIZE),
        accomodation_slider,
        GLMakie.Label(layout[n,:], "Diffuse", fontsize=CONTENT_FONTSIZE)
    )

    GLMakie.on(accomodation_slider.value) do coefficient
        gui_data.accomodation_coefficient = coefficient
    end

    # TODO add slider for wall temperature?

    return n + 1
end

# -----------------------------------------------------------------------------------------
function  add_menu_block!(layout, gui_data, n, display_size)
    GLMakie.Label(layout[n,:], "Plotting",
        fontsize = SECTION_FONTSIZE,
        halign=:left
    )

    n += 1

    symbols = [:particles, :ρ, :u, :T]
    options = ["Particles", "Density", "Velocity", "Temperature"]

    menu = GLMakie.Menu(
        layout[n,:],
        dropdown_arrow_size = CONTENT_FONTSIZE*2÷3,
        options = options,
        default = options[1],
        fontsize = CONTENT_FONTSIZE,
        cell_color_active=MENU_COLOR_ACTIVE,
        cell_color_hover=MENU_COLOR_HOVER,
        cell_color_inactive_even=MENU_COLOR_EVEN,
        cell_color_inactive_odd=MENU_COLOR_ODD,
        selection_cell_color_inactive=MENU_COLOR_INACTIVE
        # dropdown_arrow_color=
    )

    layout[n,:] = GLMakie.hgrid!(
        GLMakie.Label(layout[n,:], "Display",
            fontsize = CONTENT_FONTSIZE,
            halign=:left
        ),
        menu,
    )

    GLMakie.on(menu.selection) do _
        gui_data.display_particles[] = menu.i_selected[] == 1
        gui_data.plot_type = symbols[menu.i_selected[]]
    end

    return n + 1
end


# -----------------------------------------------------------------------------------------
function  add_object_buttons!(layout, gui_data, n, display_size; particlas_path)
    GLMakie.Label(layout[n,:], "Shapes",
        fontsize = CONTENT_FONTSIZE,
        halign=:left
    )

    n += 1

    layout[n,:] = buttongrid = GLMakie.GridLayout(tellwidth=false)

    labels = ["Triangle" "Circle"; "Random" "Capsule"]
    shape_files = ["triangle.jl" "circle.jl"; "random.jl" "capsule.jl"]
    for i in 1:2, j in 1:2
        buttongrid[i,j] = button = GLMakie.Button(layout[n,:],
            label=labels[i,j],
            fontsize = CONTENT_FONTSIZE,
            width = Int(MENU_WIDTH / 2 - 50),
            buttoncolor=BUTTON_COLOR_INACTIVE,
            buttoncolor_active=BUTTON_COLOR_ACTIVE,
            buttoncolor_hover=BUTTON_COLOR_HOVER
        )

        GLMakie.on(button.clicks) do _
            include(particlas_path * "examples/" * shape_files[i,j])
            for pt in object_points
                push!(gui_data.wall_points[], pt .* display_size ./ MESH_LENGTH)
            end
            push!(gui_data.wall_points[], Point2f(NaN))
            notify(gui_data.wall_points)

            gui_data.object_points = object_points
        end
    end

    return n + 1
end

# -----------------------------------------------------------------------------------------
function add_buttons!(layout, gui_data, n)
    button_remove_walls = GLMakie.Button(layout[n,:],
        label = "Remove Walls",
        fontsize = CONTENT_FONTSIZE,
        width = BUTTON_WIDTH,
        buttoncolor=BUTTON_COLOR_INACTIVE,
        buttoncolor_active=BUTTON_COLOR_ACTIVE,
        buttoncolor_hover=BUTTON_COLOR_HOVER
    )

    n += 1

    button_remove_particles = GLMakie.Button(layout[n,:],
        label = "Remove Particles",
        fontsize = CONTENT_FONTSIZE,
        width = BUTTON_WIDTH,
        buttoncolor=BUTTON_COLOR_INACTIVE,
        buttoncolor_active=BUTTON_COLOR_ACTIVE,
        buttoncolor_hover=BUTTON_COLOR_HOVER
    )

    n += 1

    buttonlabel = GLMakie.Observable("Play")
    button_play = GLMakie.Button(layout[n,:],
        label = buttonlabel,
        fontsize = CONTENT_FONTSIZE,
        width = BUTTON_WIDTH,
        buttoncolor=BUTTON_COLOR_INACTIVE,
        buttoncolor_active=BUTTON_COLOR_ACTIVE,
        buttoncolor_hover=BUTTON_COLOR_HOVER
    )

    GLMakie.on(button_remove_walls.clicks) do _
        gui_data.delete_walls = true
        empty!(gui_data.wall_points[])
        notify(gui_data.wall_points)
    end

    GLMakie.on(button_remove_particles.clicks) do _
        gui_data.delete_particles = true
    end

    GLMakie.on(button_play.clicks) do _
        gui_data.pause = !gui_data.pause
        buttonlabel[] = gui_data.pause ? "Play" : "Pause"
    end

    return n + 1
end

# -----------------------------------------------------------------------------------------
function add_gap!(layout, num_pixels, n)
    GLMakie.Box(layout[n,:], color=:transparent, strokewidth=0, height=num_pixels)
    return n + 1
end