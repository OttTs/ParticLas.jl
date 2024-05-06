#=
A Barrier is used to synchronize all worker threads.
When "synchronize!" is called, the thread adds one to a counter.
If all threads have added a counter, synchronization is done, otherwise wait.
=#
mutable struct Barrier
    _condition::Base.GenericCondition{ReentrantLock}
    _counter::Int8
    _num_threads::Int8
    function Barrier()
        _condition = Threads.Condition()
        return new(_condition, 0, Threads.nthreads(:default))
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

#=
In order for the GUI and Simulation threads to communicate, a SwapChannel is used.
Each has their own data that can be manipulated until swap! is called.
swap! exchanges the data!
=#
mutable struct SwapChannel{T}
    _condition::Base.GenericCondition{ReentrantLock}
    _waiting::Bool
    _data::Vector{T}
    SwapChannel(T) = new{T}(Threads.Condition(), false, [T(), T()])
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
    timing_data::TimingData

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
        zeros(Point2f, MAX_NUM_DISPLAY_PARTICLES),
        zeros(Float32, NUM_CELLS),
        TimingData()
    )
end