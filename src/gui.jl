include("gui/menu.jl")
include("gui/display.jl")
#include("gui/renderloop.jl")

function launch_window(channel, lang, path)
    GLMakie.activate!(;
        vsync = false,#true,
        framerate = 120,#FPS,
        focus_on_show = true)

    GLMakie.set_theme!(GLMakie.Theme(
        fontsize = CONTENT_FONTSIZE,
        Button = (
            width = 250,
            buttoncolor=BLUE_LIGHT,
            buttoncolor_active=BLUE_DARK,
            buttoncolor_hover=BLUE
        ),
        Toggle = (
            markersize = SLIDER_LINE_WIDTH / 0.66,
            length = SLIDER_LINE_WIDTH * 2.5,
            framecolor_active=BLUE,
            framecolor_inactive=BLUE_LIGHT,
            buttoncolor=BLUE_DARK
        ),
        Slider = (
            snap=false,
            linewidth = SLIDER_LINE_WIDTH,
            color_inactive=BLUE_LIGHT,
            color_active_dimmed=BLUE,
            color_active=BLUE_DARK
        ),
        Label = (
            fontsize = CONTENT_FONTSIZE,
            halign = :left,
        ),
        Menu = (
            dropdown_arrow_size = CONTENT_FONTSIZE * 2 ÷ 3,
            cell_color_active=BLUE,
            cell_color_hover=BLUE,
            cell_color_inactive_even=BLUE_LIGHT,
            cell_color_inactive_odd=BLUE_LIGHT,
            selection_cell_color_inactive=BLUE_LIGHT
        )
    ))

    include(path * "languages/" * lang * ".jl")

    resolution = (
        GLFW.GetVideoMode(GLFW.GetPrimaryMonitor()).width,
        GLFW.GetVideoMode(GLFW.GetPrimaryMonitor()).height
    )

    scene = GLMakie.Scene(size = resolution, camera = GLMakie.campixel!, backgroundcolor = BACKGROUND_COLOR)

    # Set up display <-> menu variables
    variable_to_plot = Observable{Symbol}(:particles)
    color_range = Observable{NTuple{2, Float32}}((NaN32, NaN32))
    walls = Observable{Vector{Point2f}}(Point2f[])
    sizehint!(walls[], 100000)


    scaling, particle_points, mesh_values = draw_display(scene, variable_to_plot, color_range, walls, channel;
        position=(BORDER_WIDTH, BORDER_WIDTH),
        size=resolution .- (3 * BORDER_WIDTH + MENU_WIDTH, 2 * BORDER_WIDTH)
    )
    draw_menu(scene, variable_to_plot, color_range, walls, channel;
        position=(resolution[1] - BORDER_WIDTH - MENU_WIDTH, BORDER_WIDTH),
        size=(MENU_WIDTH, resolution[2] - 2 * BORDER_WIDTH),
        scaling, path
    )


    # Create the gui update listener, it is called before all the others are updated
    GLMakie.on(GLMakie.events(scene).tick) do _
        # Update channel data
        keys = (:pause, :do_collisions, :inflow_density, :inflow_velocity, :accomodation_coefficient)
        tmp = NamedTuple{keys}(getfield(data(channel,1), key) for key in keys)

        # Swap data with the simulation thread
        swap!(channel,1)

        # Reset channel data
        for key in keys
            setfield!(data(channel,1), key, getfield(tmp, key))
        end
        data(channel,1).delete_particles = false
        data(channel,1).delete_walls = false
        data(channel,1).variable_to_plot = variable_to_plot[]
        empty!(data(channel,1).new_walls)
    end

    screen = GLMakie.display(scene)

    GLFW.make_fullscreen!(screen.glscreen)
end


#=
Helper functions
=#
function box(scene, position, size, color)
    # Create a box with rounded corners
    strokewidth = (√8 - 2) * SCENE_CORNER_RADIUS
    GLMakie.Box(scene,
        bbox = GLMakie.Rect(position..., size...),
        cornerradius = √2 * SCENE_CORNER_RADIUS,
        width = size[1] + strokewidth,
        height = size[2] + strokewidth,
        strokecolor = BACKGROUND_COLOR,
        strokewidth = strokewidth,
        color = color
    )
end


#mutable struct GUI
#    terminate::Bool
#    pause::Bool
#    delete_walls::Bool
#    delete_particles::Bool
#    do_collisions::Bool
#    plot_type::Observable{Symbol}
#    inflow_density::Float64
#    inflow_velocity::Float64
#    accomodation_coefficient::Float64
#    new_walls::Vector{NTuple{2, Point2f}}
#    particle_points::Observable{Vector{Point2f}}
#    mesh_values::Observable{Matrix{Float32}}
#    display_scaling::NTuple{2, Float64}
#    resolution::NTuple{2, Int64}
#    screen::GLMakie.Screen{GLFW.Window}
#
#    function GUI()
#        new_walls = NTuple{2, Point2f}[]
#        sizehint!(new_walls, 1000)
#        particle_points = Observable(zeros(Point2f, NUM_PARTICLES_VISU))
#        mesh_values = Observable(zeros(Float32, NUM_CELLS))
#        return new(
#            false, true, false, false, true,
#            Observable{Symbol}(:particles),
#            1.225 * exp(-0.11856 *DEFAULT_ALTITUDE) , DEFAULT_VELOCITY, DEFAULT_ACCOMODATION_COEFFICIENT,
#            new_walls, particle_points, mesh_values
#        )
#    end
#end

#include("gui/initialize.jl")

