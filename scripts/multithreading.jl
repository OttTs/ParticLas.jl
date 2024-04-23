# Testing multithreading to minimize overhead
# For this, the GUI thread must be spawned on :interactive
# julia itself must be started with julia --threads (N-1),1 where N is the number of physical cores

# The computation threads need to synchronize after the particle push and macroscopic calculation

# insert new particles -> move particles -> calculate thread moments
# Synchronize computation threads
# Calculate macroscopic variables from thread moments
# Synchronize computation threads
# Relax particles -> calculate thread moments
# Synchronize computation threads
# Calculate post collision macroscopic variables -> Calculate corrections
# Synchronize computation threads
# Correct the particle velocities

# Synchronize globally!

# In order to synchronize the computation threads, it may be sufficient to store a single counter.
# The counter starts at 1
# If the counter id = thread id - 1 -> update it and weight for it to be 1
#   If thread id == nthreads ->
# If this counter is one integer lower, update it
# I

mutable struct Threadlock{T}
    ids::T
    counter::Int8
    function Threadlock(first, num_threads)
        ids = range(first, length=num_threads)
        new{typeof(ids)}(ids, one(Int8))
    end
end

function busywait(ns)
    time = time_ns()
    while time_ns() - time < ns; end
end


"""
    synchronize(lock::Threadlock)

Synchronizes all the worker threads.
The threads are blocked in the meantime!
"""
function synchronize(lock::Threadlock)
    id = Threads.threadid()
    while lock.ids[lock.counter] != id
        busywait(0)
    end

    if lock.counter == length(lock.ids)
        lock.counter = 1
    else
        lock.counter += 1
    end

    while lock.counter != 1
        busywait(0)
    end
end

"""

"""
function synchronize(barrier::Threadbarrier)

end

#lock = Threadlock(Threads.nthreads(:interactive) + 1, Threads.nthreads())

#@time for i in 1:Threads.nthreads()
#    Threads.@spawn synchronize(lock)
#end


#=
TODO The interactive thread must not busywait!

From the interactive thread, the workers need:
- pause / reset / terminate
- walls / condition / ...

From the workers, the interactive thread needs
- Particle positions
or
- density / velocity / temperature

1. Send Request for data (if no open request)
2. Workers fill the open request
3. If the last worker has filled the request, we can use the data for plotting


1. Only one worker requests the stuff and then we do a synchronize!





=#