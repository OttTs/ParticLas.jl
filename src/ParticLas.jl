module ParticLas

export run_particlas

using GLMakie: Point2, Point2f, Vec, Vec2, Vec3, RGBf, Observable
import GLMakie
import GLMakie.GLFW
using LinearAlgebra
using StaticArrays: @SMatrix
using SpecialFunctions: erf
using Printf: @sprintf

mutable struct TimingData
    gui_start::Float64
    pollevents::Float64
    rendering::Float64
    communication::Float64
    copy::Float64

    sim_start::Float64
    insertion::Float64
    movement::Float64
    deposition::Float64
    collision::Float64
    TimingData() = new(0, 0, 0, 0, 0, 0, 0, 0, 0, 0)
end

include("constants.jl")
include("communication.jl")
include("simulation.jl")
include("gui.jl")

# TODO num_threads is given by Threads.nthreads(:default)

function run_particlas()
    mesh, species, time_step, barrier = setup_simulation()

    channel = SwapChannel(GUIToSimulation)

    # For the timing output:
    print(prod("\n" for i in 1:20))

    # Add simulation threads
    for threadid in 1:Threads.nthreads()
        Threads.@spawn :default try
            particles = AllocatedVector(Particle, MAX_NUM_THREAD_PARTICLES)
            simulation_thread(
                particles,
                mesh,
                species,
                time_step,
                barrier,
                channel,
                threadid
            )
        catch e
            io = open(string(thread_id, "_sim.error"), "w")
            showerror(io, e, catch_backtrace())
            close(io)
        end
    end

    # Start GUI renderloop
    #Threads.@spawn :interactive
    try
        gui_data = setup_gui()
        renderloop(gui_data, channel)
    catch e
        io = open("gui.error", "w")
        showerror(io, e, catch_backtrace())
        close(io)
    end
end

frametime() = (time_ns() / 1e9) * FPS

end