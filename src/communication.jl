#=
A Barrier is used to synchronize all worker threads.
When "synchronize!" is called, the thread adds one to a counter.
If all threads have added a counter, synchronization is done, otherwise wait.
=#

mutable struct Barrier
    _condition::Base.GenericCondition{ReentrantLock}
    _counter::Int8
    _num_threads::Int8
    function Barrier(num_threads)
        _condition = Threads.Condition()
        return new(_condition, 0, num_threads)
    end
end

function synchronize!(b::Barrier)
    lock(b._condition) do
        b._counter += 1
        if b._counter >= b._num_threads
            notify(b._condition)
            b._counter = 0
        else
            wait(b._condition, first=true)
        end
    end
end

#=
A data channel is used to communicate between the GUI and the worker thread.
=#
mutable struct DataChannel{T}
    _condition::Base.GenericCondition{ReentrantLock}
    _requested::Bool
    _sender_data::T
    _channel_data::T
    _receiver_data::T
    DataChannel(T) = new{T}(Threads.Condition(), true, T(), T(), T())
end

data(c::DataChannel) = c._receiver_data

#=
Example usage:
set!(channel) do data
    # change data here
end
=#
function set!(f, c::DataChannel)
    f(c._sender_data)
end

sender_data(c::DataChannel) = c._sender_data

# Send the data (only one thread)
function send!(c::DataChannel)
    lock(c._condition) do
        while !c._requested
            wait(c._condition, first=true)
        end

        # Swap sender data and receiver data!
        tmp = c._channel_data
        c._channel_data = c._sender_data
        c._sender_data = tmp

        c._requested = false
        notify(c._condition)
    end
end

# Receive the data
function receive!(c::DataChannel)
    lock(c._condition) do
        # Wait for sender to complete
        while c._requested
            wait(c._condition, first=true)
        end

        # Swap sender data and receiver data!
        tmp = c._receiver_data
        c._receiver_data = c._channel_data
        c._channel_data = tmp

        # Request new data
        c._requested = true
        notify(c._condition)
    end
end

mutable struct GUIToSimulation
    terminate::Bool
    pause::Bool

    plot_type::Symbol
    inflow_altitude::Float64
    inflow_velocity::Float64

    new_wall::NTuple{2, Point2f}
    accomodation_coefficient::Float64

    delete_walls::Bool
    delete_particles::Bool

    GUIToSimulation() = new(
        false,
        true,
        :particles,
        DEFAULT_ALTITUDE,
        DEFAULT_VELOCITY,
        (Point2{Float64}(NaN), Point2{Float64}(NaN)),
        DEFAULT_ACCOMODATION_COEFFICIENT,
        false,
        false
    )
end

mutable struct SimulationToGUI
    particle_positions::Vector{Point2f}
    mesh_values::Matrix{Float32}

    SimulationToGUI() = new(
        zeros(Point2f, 10^5), # maximal number of particles
        zeros(Float32, NUM_CELLS)
    )
end