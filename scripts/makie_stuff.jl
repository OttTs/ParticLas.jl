# This is a test for a simple screen using GLMakie

using GLMakie
using GLMakie.GLFW

FPS = 60
Npts = 10^4

function busywait(ns)
    time = time_ns()
    while time_ns() - time < ns; end
end


## Setup screen ---------------------------------------------------------------------------
px = GLFW.GetVideoMode(GLFW.GetPrimaryMonitor()).width
py = GLFW.GetVideoMode(GLFW.GetPrimaryMonitor()).height
window_size = (1200, 800)#(px, py)

# 1. Create a Scene and a GridLayout
scene = Scene(size=window_size, backgroundcolor=RGBf(0.8, 0.8, 0.8))

# 3. custom renderloop:
function renderloop(screen, run, fps=60)
    glscreen = screen.glscreen
    while run[]
        time = time_ns()
        # Get new events (mouse click, button pressed...) and perform actions
        GLMakie.pollevents(screen)
        # Render the new frame
        GLMakie.render_frame(screen)
        # Show the new frame on the screen
        GLFW.SwapBuffers(glscreen)
        # Allow other tasks in queue to run...
        yield()
        # Busywait for the correct FPS
        busywait(time + 10^9/fps - time_ns())
    end
    close(screen; reuse=false)
end

# Add a Keyboard listener to enable to close the window
run = Ref{Bool}(true)
on(events(scene).keyboardbutton) do button
    if button.key == Keyboard.delete
        run[] = false
    end
end


#=
ParticLas GUI
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

TitledBox
=#

# consts
BACKGROUND_COLOR = RGBf(0.8, 0.8, 0.8)
BORDER_WIDTH =
MENU_WIDTH =

function setup_screen()
    window_size = (
        GLFW.GetVideoMode(GLFW.GetPrimaryMonitor()).width,
        GLFW.GetVideoMode(GLFW.GetPrimaryMonitor()).height
    )

    scene = Scene(size=window_size, backgroundcolor=BACKGROUND_COLOR)

    display_size = window_size .- (3 * BORDER_WIDTH + MENU_WIDTH, 2 * BORDER_WIDTH)
    xyz = setup_display(scene,
        position=(BORDER_WIDTH, BORDER_WIDTH),
        display_size=display_size
    )

    setup_settings(scene,
        position=(display_size[1] + 2 * BORDER_WIDTH, BORDER_WIDTH),
        size=(MENU_WIDTH, display_size[2])
    )

    screen = GLMakie.Screen(scene, start_renderloop=false)
    GLFW.make_fullscreen!(screen.glscreen)
    return screen
end

function setup_display(scene; position, display_size)
    display_scene = Scene(scene,
        viewport=Rect(position..., display_size...),
        clear=true
    )
    campixel!(display_scene)

    # 1. Heatmap plot for physical mesh values
    mesh_variable = Observable(zeros(Float32, nx, ny))
    heatmap!(display_scene, xs, ys, mesh_variable;
        interpolate = true,
        colormap = :afmhot,
        visible = false
    )

    # 2. Scatter plot for particles
    particle_points = Observable{Vector{Point2f}}()
    scatter!(display_scene, particle_points;
        marker = GLMakie.FastPixel(),
        markersize = PARTICLES_MARKERSIZE,
        color = PARTICLES_COLOR,
        visible = true
    )

    # 3. Lines for walls
    wall_points = Observable(Vector{Point2f})()
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
        strokecolor=BACKGROUND_COLOR,
        color=:transparent
    )

    # Box 2
    Box(display_scene,
        bbox=Rect(0, 0, display_size...),
        cornerradius=SCENE_CORNER_RADIUS,
        width=display_size[1],
        height=display_size[2],
        strokewidth=SCENE_STROKE_WIDTH,
        strokecolor=SCENE_STROKE_COLOR,
        color=:transparent
    )

    # Return all Observables created for the display:
    return mesh_variable, particle_points, wall_points, display_type
end

function setup_settings(scene; position, size)

end

function Section(title, content)


end






# Size of the scene
scene_size = size(scene)
border_size = 20
menu_width = 300

# Add a new subscene for the plot
plot_scene = Scene(scene,
    viewport=Rect(
        border_size,
        border_size,
        scene_size[1]-3*border_size-menu_size,
        scene_size[2]-2*border_size
    ),
    clear=true, backgroundcolor=:white
)

# Add a new subscene for the menu
menu_scene = Scene(scene,
    viewport=Rect(
        scene_size[1] - border_size - menu_size,
        border_size,
        menu_size,
        scene_size[2]-2*border_size
    ))#,
#    clear=true, backgroundcolor=:grey
#)

campixel!(plot_scene) # Most basic camera...

campixel!(menu_scene) # Most basic camera...

println(size(menu_scene))
Box(menu_scene, cornerradius = 20, width=size(menu_scene, 1), height=size(menu_scene, 2), halign=0, valign=0, color=:grey)

# Plot stuff in the subscene
pts = [Point2f(rand(2).*size(plot_scene)) for i in 1:Npts]
sc = scatter!(plot_scene,pts;
    marker = GLMakie.FastPixel(),
    markersize = 1,
    color = :black
)

Box(plot_scene, cornerradius = 100, width=size(plot_scene)[1]+100, height=size(plot_scene)[2]+100, color=:transparent, strokewidth=100, strokecolor=RGBf(0.8, 0.8, 0.8),bbox=Rect(
    0,
    0,
    scene_size[1]-3*border_size-menu_size,
    scene_size[2]-2*border_size
))


# 2. Show the scene in a screen
screen = GLMakie.Screen(scene, start_renderloop=false)
# 2.5 Set Fullscreen
#glscreen = screen.glscreen
#GLFW.make_fullscreen!(glscreen)

# run renderloop
renderloop(screen, run)
