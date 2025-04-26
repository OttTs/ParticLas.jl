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
#include("simulation.jl")
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
    cp(pkg_path * "/logos", dst * "/bin/logos")
    cp(pkg_path * "/examples", dst * "/bin/examples")
    cp(pkg_path * "/languages", dst * "/bin/languages")
end

# TODO num_threads is given by Threads.nthreads(:default)

function julia_main()::Cint
    if length(ARGS) ≥ 1
        lang = ARGS[1]
        if length(ARGS) ≥ 2
            pdir = ARGS[2]
        else
            pdir = ""
        end
    else
        lang="english"
        pdir = ""
    end
    run_particlas(lang, pdir)
    return 0
end

# TODO do we need particlas_path?
function run_particlas(lang="english", particlas_path=string(split(pathof(ParticLas), "src")[1]))
    #particles = Particles()
    #mesh = Mesh()
    #species = Species()
    #time_step = 0.0
    gui = init_gui(lang, particlas_path)
    channel = SwapChannel(3)

    # Start simulation
    #Threads.@spawn :default try
    #    run_simulation(particles, mesh, species, time_step, channel)
    #catch e
    #    open("sim.error", "w") do io
    #        showerror(io, e, catch_backtrace())
    #    end
    #    raise_error(channel)
    #end

    # Start GUI renderloop
    #try
        renderloop(gui, channel)
    #catch e
    #    open("gui.error", "w") do io
    #        showerror(io, e, catch_backtrace())
    #    end
    #    raise_error(channel)
    #finally
        GLFW.make_windowed!(gui.screen.glscreen)
        close(gui.screen; reuse=false)
    #end
end

frametime() = (time_ns() / 1e9) * FPS

end