module ParticLas

export create_app, run_particlas

using GLMakie: Point2, Point2f, Vec, Vec2, Vec3, RGBf, Observable
import GLMakie
import GLMakie.GLFW
using LinearAlgebra
using StaticArrays: @SMatrix
using SpecialFunctions: erf
using Printf: @sprintf
import PackageCompiler

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
include("geometry.jl")
include("iterables.jl")
include("communication.jl")
include("simulation.jl")
include("gui.jl")


"""
    create_app(dst=nothing)

Create an executable to run ParticLas as a standalone app.
Use the optional argument `dst` to specify the path of the compiled app.

# Examples
```julia-repl
julia> create_app()
julia> create_app("/home/myuser/ParticLasApp")
julia> create_app("C:\\Program Files\\ParticLasApp")
```
"""
function create_app(dst=nothing)
    pkg_path = string(split(pathof(ParticLas), "src")[1])
    isnothing(dst) && (dst = string(pkg_path, "ParticLasApp"))
    PackageCompiler.create_app(pkg_path, dst, 
        precompile_execution_file="precompile.jl",
        include_lazy_artifacts=true,
        force=true
    )
end

# TODO num_threads is given by Threads.nthreads(:default)

function julia_main()::Cint
    run_particlas()
    return 0
end

function run_particlas()
    sim_data = setup_simulation()

    gui_channel = DataChannel(GUIToSimulation)
    sim_channel = DataChannel(SimulationToGUI)

    # For the timing output:
    print(prod("\n" for i in 1:20))

    # Add simulation threads
    for thread_id in 1:Threads.nthreads()
        Threads.@spawn try 
            simulation_thread(sim_data, gui_channel, sim_channel, thread_id)
        catch e
            io = open(string(thread_id, "_sim.error"), "w")
            showerror(io, e, catch_backtrace())
            close(io)
        end
    end

    # Start GUI renderloop (Threads.@spawn :interactive)
    try 
        gui_data = setup_gui()
        renderloop(gui_data, gui_channel, sim_channel)
    catch e
        io = open("gui.error", "w")
        showerror(io, e, catch_backtrace())
        close(io)
    end
end

frametime() = (time_ns() / 1e9) * FPS

end