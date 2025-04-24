mutable struct SharedData
    terminate::Bool
    pause::Bool
    delete_walls::Bool
    delete_particles::Bool
    do_collisions::Bool
    plot_type::Symbol
    inflow_altitude::Float64
    inflow_velocity::Float64
    accomodation_coefficient::Float64
    new_walls::Vector{NTuple{2, Point2f}}
    particle_positions::Vector{Point2f}
    mesh_values::Matrix{Float32}

    function SharedData()
        new_walls = NTuple{2, Point2f}[]
        sizehint!(new_walls, 1000)
        particle_positions = zeros(Point2f, MAX_NUM_PARTICLES_VISU)
        mesh_values = zeros(Float32, NUM_CELLS)
        return new(
            false, true, false, false,
            :particles,
            DEFAULT_ALTITUDE, DEFAULT_VELOCITY, DEFAULT_ACCOMODATION_COEFFICIENT,
            new_walls,
            particle_positions, mesh_values
        )
    end
end


mutable struct SwapChannel
    _condition::Base.GenericCondition{ReentrantLock}
    _current ::Vector{Int8}
    _data::Vector{SharedData}
    SwapChannel(nbins) = new(Threads.Condition(), [1, 2], [SharedData() for _ in 1:nbins])
end

function swap!(c::SwapChannel, id)
    lock(c._condition) do
        if c._current[id] + 1 == c._current[3 - id]
            # The next data bin is in use, wait until it is free
            wait(c._condition, first=true)
            c._current[id] = c._current[id] % length(c._data) + 1
        else
            c._current[id] = c._current[id] % length(c._data) + 1
            notify(c._condition)
        end
    end
end

data(c::SwapChannel, id) = c._data[c._current[id]]

function raise_error(c::SwapChannel)
    lock(c._condition) do
        notify(c._condition; error=true)
    end
end