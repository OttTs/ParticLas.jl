#=
A ThreadBarrier is used to synchronize all worker threads.
Important: The worker thread ids must start with id=1 and end with id=num_threads

id=1: Wait until all other threads sent "waiting"
id≠1: Send "waiting" and wait.
=#

mutable struct ThreadBarrier
    _waiting::Vector{Bool}
    ThreadBarrier(num_threads) = new(zeros(Bool, num_threads-1))
end

function synchronize(b::ThreadBarrier, id)
    if id == 1
        while !all(b._waiting); busywait(0); end
        b._waiting .= false
    else
        b._waiting[id-1] = true
        while b._waiting[id-1]; busywait(0); end
    end
end