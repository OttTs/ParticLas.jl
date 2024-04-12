function busywait(ns)
    time = time_ns()
    while time_ns() - time < ns; end
end

include("multithreading/synchronization.jl")
include("multithreading/communication.jl")