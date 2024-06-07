#=
A Barrier is used to synchronize all worker threads.
When "synchronize!" is called, the thread adds one to a counter.
If all threads have added a counter, synchronization is done, otherwise wait.
=#
mutable struct Barrier
    _condition::Base.GenericCondition{ReentrantLock}
    _counter::Int8
    @atomic _atomic_counter::Int8
    _num_threads::Int8
    function Barrier()
        _condition = Threads.Condition()
        return new(_condition, 0, 1, (Threads.nthreads(:default)))
    end
end

function synchronize!(b::Barrier)
    lock(b._condition) do
        b._counter += 1
        if b._counter >= b._num_threads
            b._counter = 0
            notify(b._condition)
        else
            wait(b._condition, first=true)
        end
    end
end

function synchronize_blocking!(b::Barrier, id)
    from = Int8(id)
    to = Int8(id + 1)
    ok = false
    while !ok
        _, ok = @atomicreplace(b._atomic_counter, from => to)
    end

    # Here we know that all threads are waiting
    # Now, they can leave one by one

    from = Int8(id + b._num_threads)
    to = Int8(id + b._num_threads + 1)
    ok = false
    while !ok
        _, ok = @atomicreplace(b._atomic_counter, from => to)
    end

    # The last thread needs to reset the counter before leaving
    if id == b._num_threads
        @atomic b._atomic_counter = 1
    end
end

#=
In order for the GUI and Simulation threads to communicate, a SwapChannel is used.
Each has their own data that can be manipulated until swap! is called.
swap! exchanges the data!
=#
mutable struct SwapChannel{T}
    _condition::Base.GenericCondition{ReentrantLock}
    _waiting::Bool
    @atomic _atomic_counter::Int8
    _data::Vector{T}
    SwapChannel(T) = new{T}(Threads.Condition(), false, 1, [T(), T()])
end

function swap!(c::SwapChannel)
    lock(c._condition) do
        if c._waiting
            c._data[1], c._data[2] = c._data[2], c._data[1]
            c._waiting = false
            notify(c._condition)
        else
            c._waiting = true
            wait(c._condition, first=true)
        end
    end
end

function swap_blocking!(c::SwapChannel, id)
    ok = false
    while !ok
        _, ok = @atomicreplace(c._atomic_counter, Int8(id) => Int8(id + 1))
    end

    # Now, we are both here! Let us exchange the data
    if id == 2
        c._data[1], c._data[2] = c._data[2], c._data[1]
    end

    # Now, leave one by one
    ok = false
    while !ok
        _, ok = @atomicreplace(c._atomic_counter, Int8(id + 2) => Int(id + 3))
    end

    # Last but not least, reset!
    if id == 2
        @atomic c._atomic_counter = 1
    end
end

simdata(c::SwapChannel) = c._data[1]
guidata(c::SwapChannel) = c._data[2]

#=
Data that is communicated
=#
mutable struct CommunicationData
    terminate::Bool
    pause::Bool
    plot_type::Symbol
    inflow_altitude::Float64
    inflow_velocity::Float64
    new_wall::NTuple{2, Point2f}
    accomodation_coefficient::Float64
    delete_walls::Bool
    delete_particles::Bool

    particle_positions::Vector{Point2f}
    mesh_values::Matrix{Float32}

    object_points::Vector{Point2f} # Use this if many walls shall be drawn at once. This allocates memory!

    do_collisions::Bool

    CommunicationData() = new(
        false,
        true,
        :particles,
        DEFAULT_ALTITUDE,
        DEFAULT_VELOCITY,
        (Point2{Float64}(NaN), Point2{Float64}(NaN)),
        DEFAULT_ACCOMODATION_COEFFICIENT,
        false,
        false,
        zeros(Point2f, MAX_NUM_PARTICLES_PER_THREAD * 2),#(Threads.nthreads(:default))),
        zeros(Float32, NUM_CELLS),
        Point2f[],
        true
    )
end

function raise_error(c::Union{Barrier, SwapChannel})
    lock(c._condition) do
        notify(c._condition; error=true)
    end
end