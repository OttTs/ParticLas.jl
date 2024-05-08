module ParticLas

export run_particlas

using GLMakie: Point2, Point2f, Vec, Vec2, Vec3, RGBf, Observable
import GLMakie
import GLMakie.GLFW
using LinearAlgebra
using StaticArrays: @SMatrix
using SpecialFunctions: erf
using Printf: @sprintf


include("constants.jl")
include("communication.jl")
include("simulation.jl")
include("gui.jl")

function run_particlas()
    mesh, species, time_step, barrier = setup_simulation()
    gui_data = setup_gui()

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