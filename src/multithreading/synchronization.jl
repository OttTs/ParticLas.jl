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