function busywait(ns)
    time = time_ns()
    while time_ns() - time < ns; end
end

#= Requests Workers -> GUI
- Particle positions
- Density / Velocity / Temperature

What it does:
1. Requests Data (particles / ρ / u / T)
2. Whatever
3. Retrieves requested data. If still requested, wait!


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
=#

#= Requests GUI -> Workers
TODO Tomorrow: All Interactive <--> Workers stuff
TODO Write in the julia discord and ask if it should work or not
=#

struct DataContainer

end

include("multithreading/synchronization.jl")
include("multithreading/communication.jl")