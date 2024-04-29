LABEL_PLAY_BUTTON = "Play"
LABEL_PAUSE_BUTTON = "Pause"
CLOSE_BUTTON_SIZE=24

function setup_menu(scene, display_particles, wall_points, gui_data; position, size)
    # Settings Box
    settings_bbox = Rect(position..., size...)
    Box(scene,
        bbox=settings_bbox,
        cornerradius=SCENE_CORNER_RADIUS,
        width=size[1],
        height=size[2],
        strokewidth=1,
        strokecolor=MENU_BACKGROUND_COLOR,
        color=MENU_BACKGROUND_COLOR
    )

    # Create a GridLayout for the settings
    layout = GridLayout(scene, bbox=settings_bbox, valign = :top)
    # Fix mouse position offset
    layout.parent = scene
    # Fix width of layout
    colsize!(layout, 1, Fixed(size[1] - 2 * SETTINGS_BORDER_WIDTH))

    add_close_button!(scene, settings_bbox, gui_data)
    i = add_logo!(scene, settings_bbox, layout, 1)
    i = add_gap!(layout, 10, i)
    i = add_inflow_block!(layout, gui_data, i)
    i = add_gap!(layout, 10, i)
    i = add_wall_block!(layout, gui_data, i)
    i = add_gap!(layout, 10, i)
    i = add_menu_block!(layout, gui_data, display_particles, i)
    i = add_buttons!(layout, gui_data, wall_points, i + 1)
    add_gap!(layout, 50, i)
end

# -----------------------------------------------------------------------------------------
function add_close_button!(scene, settings_bbox, gui_data)
    close_button_size = 24
    button_close = Button(scene,
        bbox=Rect(
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

    on(button_close.clicks) do _
        gui_data.terminate = true
    end
end

# -----------------------------------------------------------------------------------------
function add_logo!(scene, settings_bbox, layout, n)
    origin = settings_bbox.origin
    widths = settings_bbox.widths

    logo_size = 50
    logo = load("scripts/logo.png")
    img = image!(scene,
        (origin[1] + widths[1]÷2) .+ (-2 * logo_size, 2 * logo_size),
        origin[2] - BORDER_WIDTH + widths[2] .+ (-logo_size, 0),
        rotr90(logo)
    )
    translate!(img, (0, 0, 1)) # Put it in the foreground

    # Fix: Offset for Image...
    Box(layout[n,:], 
        color=:transparent, 
        strokewidth=0, 
        height=logo_size+BORDER_WIDTH
        )

    return n + 1
end

# -----------------------------------------------------------------------------------------
function add_inflow_block!(layout, gui_data, n, )
    Label(layout[n,:], "Inflow Conditions",
        fontsize = SECTION_FONTSIZE,
        halign=:left
    )

    n += 1

    slidergrid = SliderGrid(layout[n,:],
        (
            label = "Altitude",
            range = 80:120,
            format = "",
            startvalue = 80,
            linewidth = SLIDER_LINE_WIDTH,
            snap=false,
            color_inactive=SLIDER_COLOR_RIGHT,
            color_active_dimmed=SLIDER_COLOR_LEFT,
            color_active=SLIDER_COLOR_CIRCLE
        ),(
            label = "Velocity",
            range = 5000:10000,
            format = "",
            startvalue = 5000,
            linewidth = SLIDER_LINE_WIDTH,
            snap=false,
            color_inactive=SLIDER_COLOR_RIGHT,
            color_active_dimmed=SLIDER_COLOR_LEFT,
            color_active=SLIDER_COLOR_CIRCLE
        )
    )
    slidergrid.labels[1].fontsize[] = CONTENT_FONTSIZE
    slidergrid.labels[2].fontsize[] = CONTENT_FONTSIZE

    on(slidergrid.sliders[1].value) do altitude
        gui_data.altitude = altitude
    end

    on(slidergrid.sliders[2].value) do velocity
        gui_data.velocity = velocity
    end

    return n + 1
end

# -----------------------------------------------------------------------------------------
function add_wall_block!(layout, gui_data, n)
    Label(layout[n,:], "Wall Interaction",
        fontsize = SECTION_FONTSIZE,
        halign=:left
    )

    n += 1

    accomodation_slider = Slider(layout[n,:],
        range=0:0.01:1,
        startvalue=0,
        linewidth = SLIDER_LINE_WIDTH,
        snap=false,
        color_inactive=SLIDER_COLOR_RIGHT,
        color_active_dimmed=SLIDER_COLOR_LEFT,
        color_active=SLIDER_COLOR_CIRCLE
    )
    layout[n,:] = hgrid!(
        Label(layout[n,:], "Diffuse", fontsize=CONTENT_FONTSIZE),
        accomodation_slider,
        Label(layout[n,:], "Specular", fontsize=CONTENT_FONTSIZE)
    )

    on(accomodation_slider.value) do coefficient
        gui_data.accomodation_coefficient = coefficient
    end

    # TODO add slider for wall temperature?

    return n + 1
end

# -----------------------------------------------------------------------------------------
function  add_menu_block!(layout, gui_data, display_particles, n)
    Label(layout[n,:], "Plotting",
        fontsize = SECTION_FONTSIZE,
        halign=:left
    )

    n += 1

    symbols = [:particles, :ρ, :u, :T]
    options = ["Particles", "Density", "Velocity", "Temperature"]

    layout[n,:] = hgrid!(
        Label(layout[n,:], "Display",
            fontsize = CONTENT_FONTSIZE,
            halign=:left
        ),
        Menu(
            layout[n,:],
            dropdown_arrow_size = CONTENT_FONTSIZE*2÷3,
            options = options,
            default = PARTICLE_LABEL,
            fontsize = CONTENT_FONTSIZE,
            cell_color_active=MENU_COLOR_ACTIVE,
            cell_color_hover=MENU_COLOR_HOVER,
            cell_color_inactive_even=MENU_COLOR_EVEN,
            cell_color_inactive_odd=MENU_COLOR_ODD,
            selection_cell_color_inactive=MENU_COLOR_INACTIVE
            # dropdown_arrow_color=
        )
    )

    on(menu.selection) do _
        display_particles[] = menu.i_selected == 1
        gui_data.plot_type = symbols[menu.i_selected]
    end

    return n + 1
end

# -----------------------------------------------------------------------------------------
function add_buttons!(layout, gui_data, wall_points, n)
    button_remove_walls = Button(layout[n,:],
        label = "Remove Walls",
        fontsize = CONTENT_FONTSIZE,
        width = BUTTON_WIDTH,
        buttoncolor=BUTTON_COLOR_INACTIVE,
        buttoncolor_active=BUTTON_COLOR_ACTIVE,
        buttoncolor_hover=BUTTON_COLOR_HOVER
    )

    n += 1

    button_remove_particles = Button(layout[n,:],
        label = "Remove Particles",
        fontsize = CONTENT_FONTSIZE,
        width = BUTTON_WIDTH,
        buttoncolor=BUTTON_COLOR_INACTIVE,
        buttoncolor_active=BUTTON_COLOR_ACTIVE,
        buttoncolor_hover=BUTTON_COLOR_HOVER
    )

    n += 1

    buttonlabel = Observable("Play")
    button_play = Button(layout[n,:],
        label = buttonlabel,
        fontsize = CONTENT_FONTSIZE,
        width = BUTTON_WIDTH,
        buttoncolor=BUTTON_COLOR_INACTIVE,
        buttoncolor_active=BUTTON_COLOR_ACTIVE,
        buttoncolor_hover=BUTTON_COLOR_HOVER
    )

    on(button_remove_walls.clicks) do _
        gui_data.delete_walls = true
        empty!(wall_points[])
        notify(wall_points)
    end 

    on(button_remove_particles.clicks) do _
        gui_data.delete_particles = true
    end

    on(button_play.clicks) do _
        gui_data.pause = !gui_data.pause
        buttonlabel[] = gui_data.pause ? "Play" : "Pause"
    end

    return n + 1
end

# -----------------------------------------------------------------------------------------
function add_gap!(layout, num_pixels, n)
    Box(layout[n,:], color=:transparent, strokewidth=0, height=num_pixels)
    return n + 1
end