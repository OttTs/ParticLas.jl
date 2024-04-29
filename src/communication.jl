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
        return new(_condition, Base.RefValue{Int8}(0), num_threads)
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
Each thread gets its own channel to send particle / mesh data,
If requested is true, the sender can insert data to the cannel, otherwise wait!
If requested is false, the receiver can read the data, otherwise wait

Senders can edit their data as they want until they are done!
Then the receiver calls receive!() which swaps the data!
=#

# TODO We need 3 data stuff? Then, send is called by only one thread! after sync
# If there are 3, we can do what we want.
mutable struct DataChannel{T}
    _condition::Vector{Base.GenericCondition{ReentrantLock}}
    _requested::Vector{Bool}
    _sender_data::T
    _receiver_data::T
    DataChannel(T, num_senders=1) = new{T}(
        [Threads.Condition() for _ in 1:num_senders],
        zeros(Bool, num_senders),
        T(), T()
    )
end

data(c::DataChannel) = c._receiver_data

#=
Example usage:
send!(channel, id) do data
    # change data here
end
=#
function send!(f, c::DataChannel, id=1)
    lock(c._condition[id]) do
        while !c._requested[id]
            wait(c._condition[id], first=true)
        end
        f(c._sender_data)
        c._requested[id] = false
        notify(c._condition[id])
    end
end

#=
Swaps the sender and receiver data.
After calling receive!, the new data can be accessed by calling data(c::DataChannel)
=#
function receive!(c::DataChannel)
    # Wait for all senders to complete
    for i in 1:length(c._condition)
        lock(c._condition[i]) do
            while c._requested[i]
                wait(c._condition[i], first=true)
            end
        end
    end

    # Swap sender data and receiver data!
    tmp = c._receiver_data
    c._receiver_data = c._sender_data
    c._sender_data = tmp

    # Request new data
    for i in 1:length(c._condition)
        lock(c._condition[i]) do
            c._requested[i] = true
            notify(c._condition[id])
        end
    end
end