#=
GUIData is used for communicating the GUI data to the simulation threads.
=#
mutable struct GUIData
    terminate::Bool
    pause::Bool
    delete_particles::Bool
    delete_walls::Bool

    new_wall::NTuple{2, Point2{Float64}}
    accomodation_coefficient::Float64

    inflow_altitude::Float64
    inflow_velocity::Float64

    plot_type::Symbol # :particles, :density, :velocity, :temperature
    GUIData() = new(
        false, false, false, false, # todo pause = true
        (Point2f(NaN,NaN), Point2f(NaN,NaN)),
        0, 0, 0,
        :particles
    )
end

function Base.copy!(dst::GUIData, src::GUIData)
    for i in fieldnames(GUIData)
        setfield!(dst, i, getfield(src, i))
    end
end

include("gui/constants.jl")
include("gui/drawing_display.jl")
include("gui/settings_menu.jl")

function setup_gui()
    # Get Window size and create Scene
    window_size = (
        GLFW.GetVideoMode(GLFW.GetPrimaryMonitor()).width,
        GLFW.GetVideoMode(GLFW.GetPrimaryMonitor()).height
    )

    gui_data = GUIData()

    scene = GLMakie.Scene(size=window_size, backgroundcolor=BACKGROUND_COLOR)
    GLMakie.campixel!(scene)

    # Setup display to show simulation
    display_size =
        window_size .- (3, 2) .* BORDER_WIDTH .- (MENU_WIDTH, 0)
    mesh_variable, particle_points, display_particles, wall_points = setup_display(
        scene,
        gui_data;
        position=BORDER_WIDTH .* (1, 1),
        size=display_size
    )

    # Setup the settings menu
    terminate = setup_menu(scene, display_particles, wall_points, gui_data;
        position=(display_size[1], 0) .+ BORDER_WIDTH .* (2, 1),
        size=(MENU_WIDTH, display_size[2])
    )

    screen = GLMakie.Screen(scene, start_renderloop=false)
    GLFW.make_fullscreen!(screen.glscreen)

    return screen, display_size, mesh_variable, particle_points, terminate
end

frametime(fps) = (time_ns() / 1e9) * fps

function renderloop(screen, particle_points, mesh_variable, terminate, gui_channel, sim_channel)
    gui_data = sender_data(gui_channel)
    while !terminate[]
        starttime = frametime(FPS)

        # Reset the data
        gui_data.new_wall = (Point2{Float64}(NaN), Point2{Float64}(NaN))
        gui_data.delete_particles = false
        gui_data.delete_walls = false

        # Get new evenets and render new frame
        GLMakie.pollevents(screen)
        GLMakie.render_frame(screen)
        GLFW.SwapBuffers(screen.glscreen)

        # Send the gui data
        #gui_data.terminate = terminate[]
        #send!(gui_channel)

        # Receive the simulation data for the new time step
        #receive!(sim_channel)
        #if gui_data.plot_type == :particles
        #    particle_points[] = data(sim_channel).particle_positions
        #else
        #    mesh_variable[] = data(sim-channel).mesh_values
        #end

        # Wait for the rest of the frame
        dur = (frametime(FPS) - starttime) / 60
        dur > 0.01 && sleep(0.8 * dur)
        while frametime(FPS) - starttime < 1; end

    end
    GLFW.make_windowed!(screen.glscreen)
    close(screen; reuse=false)
end