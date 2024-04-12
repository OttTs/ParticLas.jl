
# A worker that allocates does not need a safepoint
function allocatingwait(ns)
    time = time_ns()
    while time_ns() - time < ns
        rand(10^8)
    end
    println("Allocating id ", Threads.threadid(), " done!")
end

# A worker that does not allocate does need one
function busywait(ns)
    time = time_ns()
    while time_ns() - time < ns
        GC.safepoint()
    end
    println("Thread id ", Threads.threadid(), " done!")
end

GC.enable_logging()

Threads.@spawn allocatingwait(10000000000)
Threads.@spawn busywait(10000000000)
Threads.@spawn busywait(10000000000)
#Threads.@spawn busywait(10000000000)
#Threads.@spawn busywait(10000000000)
#Threads.@spawn allocatingwait(10000000000)
#busywait(10000000000)

println("Done!")

# When starting julia, the number of gcthreads must be defined!
# Ithink