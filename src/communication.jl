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
    DataChannel(x) = new{typeof(x)}(Threads.Condition(), false, x, deepcopy(x), deepcopy(x))
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
        notify(c._condition[id])
    end
end