



function renderloop()

    while !terminate

        # Update data
        data_container = getfield(simulation_data_containers, current_plot)
        # TODO maybe replace by waitfor(data_container) -> waits until it is free
        if !isbusy(data_container)
            # Copy data and request new data
            copydata!(data_container)
            copyto!(getfield(plot_data, current_plot), data_container)
            requestdata(data_container)
        end
    end
end