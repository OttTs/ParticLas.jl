module ParticLas

export run_particlas

using GLMakie: Point2, Point2f, Vec, Vec2, Vec3, RGBf, Observable
import GLMakie
import GLMakie.GLFW
using LinearAlgebra
using StaticArrays: @SMatrix
using SpecialFunctions: erf

include("constants.jl")
include("geometry.jl")
include("iterables.jl")
include("communication.jl")
include("simulation.jl")
include("gui.jl")

# TODO num_threads is given by Threads.nthreads(:default)

function run_particlas()
    gui_data = setup_gui()
    sim_data = setup_simulation()

    gui_channel = DataChannel(GUIToSimulation)
    sim_channel = DataChannel(SimulationToGUI)

    # Add simulation threads
    #for thread_id in 1:Threads.nthreads()
    #    Threads.@spawn simulation_thread(sim_data, gui_channel, sim_channel, thread_id)
    #end
    @async simulation_thread(sim_data, gui_channel, sim_channel, 1)


    renderloop(gui_data, gui_channel, sim_channel)



    # Start GUI renderloop
    #Threads.@spawn :interactive

end

end