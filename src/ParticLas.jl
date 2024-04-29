module ParticLas

using GLMakie: Point2, Vec, Vec2, Vec3
using LinearAlgebra
using StaticArrays: @SMatrix
using SpecialFunctions: erf

include("geometry.jl")
include("iterables.jl")
include("simulation.jl")

function run_particlas(num_sim_threads)
    # Set up the GUI
    screen, display_size, mesh_variable, particle_points = setup_gui()

    # Set up simulation
    species = Species(1E21, 6.63E-26, 273, 0.77; ref_diameter=4.05E-10)
    particles = ThreadedVector(Particle, num_sim_threads)
    mesh = Mesh(
        display_size ./ display_size[1],
        round.(Int, display_size .* (80 / display_size[1])),
        num_sim_threads
    )
    inflow = InflowCondition()
    wall_condition = WallCondition()
    time_step = 1E-6

    # Set up communication
    barrier = Barrier(num_sim_threads)
    gui_channel = DataChannel(GUIData, num_sim_threads)
    sim_channel = DataChannel(SimulationData)

    # Add simulation threads
    for thread_id in 1:num_sim_threads
        Threads.@spawn simulation_thread(
            particles[thread_id],
            species,
            mesh,
            inflow,
            wall_condition,
            time_step,
            barrier,
            gui_channel,
            sim_channel,
            thread_id
        )
    end

    # Start GUI renderloop
    Threads.@spawn :interactive renderloop(
        screen, 
        gui_data, 
        particle_points, 
        mesh_variable, 
        gui_channel, 
        sim_channel
    )
end

end