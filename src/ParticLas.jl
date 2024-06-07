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


include("constants.jl")
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
    pkg_path = string(split(pathof(ParticLas), "/src")[1])
    isnothing(dst) && (dst = string(pkg_path, "/ParticLasApp"))
    dst = string(rstrip(dst, '/'))
    PackageCompiler.create_app(pkg_path, dst,
        precompile_execution_file=pkg_path * "/precompile.jl",
        include_lazy_artifacts=true,
        force=true
    )
    cp(pkg_path * "/logos", dst * "/bin")
    cp(pkg_path * "/examples", dst * "/bin")
end

# TODO num_threads is given by Threads.nthreads(:default)

function julia_main()::Cint
    if length(ARGS) ≥ 1
        lang = ARGS[1]
    else
        lang="egnlish"
    end
    run_particlas(lang, "")
    return 0
end

function run_particlas(lang="english", particlas_path=string(split(pathof(ParticLas), "src")[1]))


    mesh, species, time_step, barrier = setup_simulation()
    gui_data = setup_gui(lang, particlas_path)

    channel = SwapChannel(CommunicationData)


    # Add simulation threads
    for threadid in 1:(Threads.nthreads(:default))
        Threads.@spawn :default try
            particles = AllocatedVector(Particle, MAX_NUM_PARTICLES_PER_THREAD)
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
            io = open(string(threadid, "_sim.error"), "w")
            showerror(io, e, catch_backtrace())
            close(io)
            sleep(0.2)
            raise_error(barrier)
            raise_error(channel)
        end
    end

    # Start GUI renderloop
    try
        renderloop(gui_data, channel)
    catch e
        io = open(string("gui.error"), "w")
        showerror(io, e, catch_backtrace())
        close(io)
        sleep(0.2)
        raise_error(channel)
    finally
        GLFW.make_windowed!(gui_data.screen.glscreen)
        close(gui_data.screen; reuse=false)
    end
end

frametime() = (time_ns() / 1e9) * FPS

end