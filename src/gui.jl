# The renderloop is the only task that busywaits!
function busywait(ns)
    time = time_ns()
    while time_ns() - time < ns; end
end

# The simulation loop should do the simulation and wait for the renderloop


function renderloop()

    while !terminate

        # Update data
        data_container = getfield(simulation_data_containers, current_plot)
        # TODO maybe replace by waitfor(data_container) -> waits until it is free
        #if !isbusy(data_container)
        #    # Copy data and request new data
        #    # Let's do it with channels...
        #    copydata!(data_container)
        #    copyto!(getfield(plot_data, current_plot), data_container)
        #    requestdata(data_container)
        #end

        # Send out settings data
        # send_settings()
        # receive_plot_data()
    end
end