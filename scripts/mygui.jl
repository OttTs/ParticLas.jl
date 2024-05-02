using GLMakie
using GLMakie.GLFW
using FileIO

# consts
GUI_BACKGROUND_COLOR = "#1c618f"#RGBf(0.1, 0.1, 0.3)
BORDER_WIDTH = 20
MENU_WIDTH = 400
BUTTON_WIDTH = 250

PARTICLES_BACKGROUND_COLOR = :white
PARTICLES_MARKERSIZE = 1
PARTICLES_COLOR = :black

WALL_LINEWIDTH = 1
WALL_COLOR = :blue

SCENE_CORNER_RADIUS = 20
# It is 1 and matches the box color otherwise, antialiasing does not work
#SCENE_STROKE_WIDTH = 0
#SCENE_STROKE_COLOR = :transparent

LOGO_SIZE = 100
VSPACE_LOGO_INFLOW = 0
SECTION_FONTSIZE = 30
VSPACE_SECTION_TITLE_CONTENT=10

MIN_ALTITUDE = 80
MAX_ALTITUDE = 120
MIN_VELOCITY = 1000
MAX_VELOCITY = 10000

SLIDER_LINE_WIDTH = 20
CONTENT_FONTSIZE = 20

INFLOW_LABEL = "Inflow conditions"
ALTITUDE_LABEL = "Altitude"
VELOCITY_LABEL = "Velocity"

SLIDER_COLOR_RIGHT=:green
SLIDER_COLOR_LEFT=:blue
SLIDER_COLOR_CIRCLE=:green

VSPACE_INFLOW_WALLS = 10

SETTINGS_BORDER_WIDTH=10

WALL_ACCOMODATION_LABEL="Wall interaction"
WALL_DIFFUSE_LABEL="Diffuse"
WALL_SPECULAR_LABEL="Specular"

DISPLAY_LABEL="Display"
PLOT_TYPE_LABEL="Plot"

PARTICLE_LABEL="Particles"
DENSITY_LABEL="Density"
VELOCITY_LABEL="Velocity"
TEMPERATURE_LABEL="Temperature"

# Setup colors
COLOR_ACCENT=RGBf(0.6,0.078,0.247)
COLOR_ACCENT_DIMMED=RGBf(0.11, 0.38, 0.57)
COLOR_INACTIVE=RGBf(1,1,1)

function setup_screen()
    # Set colors
    GLMakie.Makie.COLOR_ACCENT[] = COLOR_ACCENT
    GLMakie.Makie.COLOR_ACCENT_DIMMED[] = COLOR_ACCENT_DIMMED

    # Get Window size and create Scene
    window_size = (
        GLFW.GetVideoMode(GLFW.GetPrimaryMonitor()).width,
        GLFW.GetVideoMode(GLFW.GetPrimaryMonitor()).height
    )
    window_size = (1200, 800)

    scene = Scene(size=window_size, backgroundcolor=GUI_BACKGROUND_COLOR)
    campixel!(scene)

    # Setup display to show simulation
    display_size = window_size .- (3 * BORDER_WIDTH + MENU_WIDTH, 2 * BORDER_WIDTH)
    xyz = setup_display(scene,
        position=(BORDER_WIDTH, BORDER_WIDTH),
        display_size=display_size
    )

    # Setup the settings menu
    setup_settings(scene,
        position=(display_size[1] + 2 * BORDER_WIDTH, BORDER_WIDTH),
        settings_size=(MENU_WIDTH, display_size[2])
    )

    # Show the screen
    screen = GLMakie.Screen(scene, start_renderloop=true) # TODO set start_renderloop to false
    #GLFW.make_fullscreen!(screen.glscreen)

    # return all variables that interact with the simulation
    return screen
end

function setup_display(scene; position, display_size)
    display_scene = Scene(scene,
        viewport=Rect(position..., display_size...),
        backgroundcolor=PARTICLES_BACKGROUND_COLOR,
        clear=true
    )
    campixel!(display_scene)

    # 1. Heatmap plot for physical mesh values
    #mesh_variable = Observable(zeros(Float32, nx, ny))
    #heatmap!(display_scene, xs, ys, mesh_variable;
    #    interpolate = true,
    #    colormap = :afmhot,
    #    visible = false
    #)

    # 2. Scatter plot for particles
    particle_points = Observable(Point2f[])
    scatter!(display_scene, particle_points;
        marker = GLMakie.FastPixel(),
        markersize = PARTICLES_MARKERSIZE,
        color = PARTICLES_COLOR,
        visible = true
    )

    # 3. Lines for walls
    wall_points = Observable(Point2f[])
    lines!(display_scene, wall_points;
        linewidth = WALL_LINEWIDTH,
        color = WALL_COLOR
    )

    #=
    Create two Boxes.
    The first box creates rounded edges of the display_scene.
    The second box is used to create a bounding stroke.
    =#
    # Box 1
    stroke_width = (√8 - 2) * SCENE_CORNER_RADIUS
    Box(display_scene,
        bbox=Rect(0, 0, display_size...),
        cornerradius=√2 * SCENE_CORNER_RADIUS,
        width=display_size[1] + stroke_width,
        height=display_size[2] + stroke_width,
        strokewidth=stroke_width,
        strokecolor=GUI_BACKGROUND_COLOR,
        color=:transparent
    )

    # Box 2
    #Box(display_scene,
    #    bbox=Rect(0, 0, display_size...),
    #    cornerradius=SCENE_CORNER_RADIUS,
    #    width=display_size[1],
    #    height=display_size[2],
    #    strokewidth=0#SCENE_STROKE_WIDTH,
    #    strokecolor=SCENE_STROKE_COLOR,
    #    color=:transparent
    #)

    # Return all Observables created for the display:
    #return mesh_variable, particle_points, wall_points, display_type
    return nothing
end

function setup_settings(scene; position, settings_size)
#=
Scene
|- Plot Scene
|   |- Heatmap Plot
|   |- Scatter Plot
|   |- Lines Plot
|   |- Box (For rounded corners)
|   |- Box (For bounding stroke)
|
|- Settings Scene
    |- Box
    |- Inflow
    |   |- Text (title)
    |   |- Text + Slider (Slider with title)
    |   |- Text + Slider
    |
    |- Walls
    |   |– Text
    |   |- Text + Slider
    |
    |- Plot Type
    |   |– Text
    |   |– Menu
    |
    |
    |- Button (delete Particles (left) and Walls (right))
    |- Button (Play / Pause)
=#
    # Settings Box
    settings_bbox = Rect(position..., settings_size...)
    Box(scene,
        bbox=settings_bbox,
        cornerradius=SCENE_CORNER_RADIUS,
        width=settings_size[1],
        height=settings_size[2],
        strokewidth=1,#SCENE_STROKE_WIDTH,
        strokecolor="#c8f9e1",#SCENE_STROKE_COLOR,
        color="#c8f9e1"#RGBf(0.6,0.6,0.8)  SETTINGS_BACKGROUND_COLOR
    )

    # Close button
    CLOSE_BUTTON_SIZE=24
    Button(scene,
        bbox=Rect(
            (position.+settings_size.-CLOSE_BUTTON_SIZE.-10)...,
            CLOSE_BUTTON_SIZE,
            CLOSE_BUTTON_SIZE
        ),
        label = "✕",
        height=CLOSE_BUTTON_SIZE,#24,
        width=CLOSE_BUTTON_SIZE,
        cornerradius=CLOSE_BUTTON_SIZE÷2,
        buttoncolor=RGBf(0.2, 0.2, 0.2),
        buttoncolor_hover=RGBf(0.8, 0.2, 0.2),
        buttoncolor_active=RGBf(0.5, 0.2, 0.2),
        labelcolor=RGBf(0.8,0.8,0.8),
        labelcolor_active=RGBf(0.8,0.8,0.8),
        labelcolor_hover=RGBf(0.8,0.8,0.8),
        fontsize=(CLOSE_BUTTON_SIZE*2)÷3,
        strokecolor="#c8f9e1",#SETTINGS_BACKGROUND_COLOR,
        strokewidth=1
    )

    # ParticLas Logo
    logo = load("scripts/logo.png")
    img = image!(scene,
        (position[1] + settings_size[1]÷2) .+ (-2*LOGO_SIZE,2*LOGO_SIZE),
        position[2] - BORDER_WIDTH + settings_size[2] .+ (-LOGO_SIZE,0),
        rotr90(logo)
    )
    translate!(img, (0, 0, 1)) # Put it in the foreground


    # Create a GridLayout for the settings
    layout = GridLayout(scene, bbox=settings_bbox, valign = :top)
    # Fix mouse position offset
    layout.parent = scene
    # Fix width of layout
    colsize!(layout, 1, Fixed(settings_size[1] - 2 * SETTINGS_BORDER_WIDTH))
    # Fix: Offset for Image...
    Box(layout[1,:], color=:transparent, strokewidth=0, height=LOGO_SIZE+BORDER_WIDTH)

    # -------------------------------------------------------------------------------------
    # Inflow conditions
    Label(layout[2,:], INFLOW_LABEL,
        fontsize = SECTION_FONTSIZE,
        halign=:left
    )

    sg = SliderGrid(layout[3,:],
        (
            label = ALTITUDE_LABEL,
            range = MIN_ALTITUDE:MAX_ALTITUDE,
            format = "",
            startvalue = MIN_ALTITUDE,
            linewidth = SLIDER_LINE_WIDTH,
            snap=false,
            color_inactive=COLOR_INACTIVE,
            #color_active_dimmed=SLIDER_COLOR_LEFT,
            #color_active=SLIDER_COLOR_CIRCLE,
        ),(
            label = VELOCITY_LABEL,
            range = MIN_VELOCITY:MAX_VELOCITY,
            format = "",
            startvalue = MIN_VELOCITY,
            linewidth=SLIDER_LINE_WIDTH,
            snap=false,
            color_inactive=COLOR_INACTIVE,
            #color_active_dimmed=SLIDER_COLOR_LEFT,
            #color_active=SLIDER_COLOR_CIRCLE
        )
    )
    sg.labels[1].fontsize[] = CONTENT_FONTSIZE
    sg.labels[2].fontsize[] = CONTENT_FONTSIZE

    # -------------------------------------------------------------------------------------
    # Wall accomodation coefficient
    Label(layout[4,:], WALL_ACCOMODATION_LABEL,
        fontsize = SECTION_FONTSIZE,
        halign=:left
    )
    accomodation_slider = Slider(layout[5,:],
        range=0:0.01:1,
        startvalue=0,
        linewidth=SLIDER_LINE_WIDTH,
        snap=false,
        color_inactive=COLOR_INACTIVE,
        #color_active_dimmed=SLIDER_COLOR_LEFT,
        #color_active=SLIDER_COLOR_CIRCLE
    )
    layout[5,:] = hgrid!(
        Label(layout[5,:], WALL_SPECULAR_LABEL, fontsize=CONTENT_FONTSIZE),
        accomodation_slider,
        Label(layout[5,:], WALL_DIFFUSE_LABEL, fontsize=CONTENT_FONTSIZE)
    )

    # -------------------------------------------------------------------------------------
    # Plot type Menu
    Label(layout[6,:], DISPLAY_LABEL,
            fontsize = SECTION_FONTSIZE,
            halign=:left
    )
    layout[7,:] = hgrid!(
        Label(layout[7,:], PLOT_TYPE_LABEL,
            fontsize = CONTENT_FONTSIZE,
            halign=:left
        ),
        Menu(
            layout[7,:],
            dropdown_arrow_size = CONTENT_FONTSIZE*2÷3,
            options = [PARTICLE_LABEL, DENSITY_LABEL, VELOCITY_LABEL, TEMPERATURE_LABEL],
            default = PARTICLE_LABEL,
            fontsize = CONTENT_FONTSIZE,
            cell_color_inactive_even=COLOR_INACTIVE,
            cell_color_inactive_odd=COLOR_INACTIVE,
            selection_cell_color_inactive=COLOR_INACTIVE
            # dropdown_arrow_color=
        )
    )

    Button(layout[9,:],
        label = "Remove Walls",
        buttoncolor=COLOR_INACTIVE,
        fontsize = CONTENT_FONTSIZE,
        width = BUTTON_WIDTH
    )
    Button(layout[10,:],
        label = "Remove Particles",
        buttoncolor=COLOR_INACTIVE,
        fontsize = CONTENT_FONTSIZE,
        width = BUTTON_WIDTH
    )

    Button(layout[11,:],
        label = "Play",
        buttoncolor=COLOR_INACTIVE,
        fontsize = CONTENT_FONTSIZE,
        width = BUTTON_WIDTH
    )

    # Fix: Add box for rowgap after last item
    Box(layout[12,:], color=:transparent, strokewidth=0, height=50)

    #rowsize!(layout, 9, Relative(0.15))

    rowgap!(layout, 3, Relative(0.05))
    rowgap!(layout, 5, Relative(0.05))





end



    ##vertical_position = position[2] + settings_size[2]
##
    ### -------------------------------------------------------------------------------------
    ### 1. ParticLas Logo
    ##vertical_position -= LOGO_SIZE
    ##img = load("scripts/logo.png")
    ##imm = image!(scene, img,
    ##    (position[1] + settings_size[1]÷2) .+ (-LOGO_SIZE÷2,LOGO_SIZE÷2),
    ##    vertical_position .+ (1,LOGO_SIZE),
    ##    rotr90(img)
    ##)
    ##translate!(imm, (0, 0, 1)) # Put it in the foreground
##
    ### Distance between image and Inflow
    ##vertical_position -= VSPACE_LOGO_INFLOW
##
    ### -------------------------------------------------------------------------------------
    ### 2. Inflow Conditions
    ##vertical_position -= SECTION_FONTSIZE
    ##Label(scene, INFLOW_LABEL,
    ##    bbox=Rect(position[1], vertical_position, settings_size[1], SECTION_FONTSIZE),
    ##    fontsize = SECTION_FONTSIZE
    ##)
    ##vertical_position -= VSPACE_SECTION_TITLE_CONTENT
##
    ##vertical_position -= 3 * CONTENT_FONTSIZE
    ##sg = SliderGrid(scene,
    ##    bbox=Rect(position[1], vertical_position, settings_size[1], 3 * CONTENT_FONTSIZE),
    ##    width=settings_size[1]-20,
    ##    (
    ##        label = ALTITUDE_LABEL,
    ##        range = MIN_ALTITUDE:MAX_ALTITUDE,
    ##        format = "",
    ##        startvalue = MIN_ALTITUDE,
    ##        linewidth = SLIDER_LINE_WIDTH,
    ##        snap=false,
    ##        color_inactive=SLIDER_COLOR_RIGHT,
    ##        color_active_dimmed=SLIDER_COLOR_LEFT,
    ##        color_active=SLIDER_COLOR_CIRCLE
    ##    ),(
    ##        label = VELOCITY_LABEL,
    ##        range = MIN_VELOCITY:MAX_VELOCITY,
    ##        format = "",
    ##        startvalue = MIN_VELOCITY,
    ##        linewidth=SLIDER_LINE_WIDTH,
    ##        snap=false,
    ##        color_inactive=SLIDER_COLOR_RIGHT,
    ##        color_active_dimmed=SLIDER_COLOR_LEFT,
    ##        color_active=SLIDER_COLOR_CIRCLE
    ##    )
    ##)
    ##sg.labels[1].fontsize[] = CONTENT_FONTSIZE
    ##sg.labels[2].fontsize[] = CONTENT_FONTSIZE
##
    ##vertical_position -= VSPACE_INFLOW_WALLS
##
    ### -------------------------------------------------------------------------------------
    ### 3. Walls accomodation coefficient
    ##vertical_position -= SECTION_FONTSIZE
    ##Label(scene, "Test",#WALL_LABEL,
    ##    bbox=Rect(position[1], vertical_position, settings_size[1], SECTION_FONTSIZE),
    ##    fontsize = SECTION_FONTSIZE
    ##)
##
    ### Slider
##
    ### Plot type title

    # Menu

    # Button, Button, Button


    #current_position



    #Slider(scene, bbox=Rect(position[1], 650, settings_size[1], 100),
    #range = 0:0.01:10, startvalue = 3, linewidth=20, snap=false, width=settings_size[1]-20)
#
    #Toggle(scene, bbox=Rect(position[1], 600, settings_size[1], 100),
    #active = true, height=30, width=60)
#
    #Menu(scene, bbox=Rect(position[1], 50, settings_size[1], 100),
    #options = ["Square Root", "Square", "Sine", "Cosine"],
    #default = "Square",
    #width=settings_size[1]-20)
#
#
    #Button(scene, bbox=Rect(position[1], 100, settings_size[1], 100), label = "Play", font="Comic Sans")

    #add_section(
    #    "Inflow",
    #    content,
    #    boundingbox=settings_bbox)

setup_screen()