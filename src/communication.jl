# TODO Busywait is actually only used in the renderloop for correct 60 fps
function busywait(ns)
    time = time_ns()
    while time_ns() - time < ns; end
end

#=
A Barrier is used to synchronize all worker threads.
When "synchronize!" is called, the thread adds one to a counter.
If all threads have added a counter, synchronization is done, otherwise wait.
=#

struct Barrier{T}
    _condition::T
    _counter :: Base.RefValue{Int8}
    _num_threads::Int8
    function Barrier(num_threads)
        _condition = Threads.Condition()
        return new{typeof(_condition)}(_condition, Base.RefValue{Int8}(0), num_threads)
    end
end

function synchronize!(b::Barrier)
    lock(b._condition)
    try
        b._counter[] += 1
        if b._counter[] >= b._num_threads
            notify(b._condition)
            b._counter[] = 0
        else
            wait(b._condition)
        end
    finally
        unlock(b._condition)
    end
end


# Channels...
#
#=
From the interactive thread, the workers need:
- pause / reset (particles, walls) / terminate
- walls
- Inflow condition (velocity, density)
- Wall accomodation_coefficient
- do collisions

From the workers, the interactive thread needs
- Particle positions
or
- density / velocity / temperature

What is always the same?

=#

struct SettingsData
    terminate::Bool
    pause::Bool
    delete_particles::Bool
    delete_walls::Bool

    do_particle_collisions::Bool

    drawn_wall::NTuple{2, Point2{Float64}}
    accomodation_coefficient::Float64

    inflow_density::Float64
    inflow_velocity::Float64

    draw_type::Symbol # :particles, :density, :velocity, :temperature
end