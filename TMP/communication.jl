# Channels...
# 
#=
From the interactive thread, the workers need:
- pause / reset (particles, walls) / terminate
- walls
- Inflow condition (velocity, density)
- Wall accomodation_coefficient
- do collisions

From the workers, the interactive thread needs
- Particle positions
or
- density / velocity / temperature

What is always the same?

=#
struct DataChannel{T}
    _data::Vector{T}
    _data_sent::Vector{Bool}
    function DataChannel(data::T, num_senders) where T
        _data = collect(deepcopy(data) for i in 1:num_senders)
        _data_sent = zeros(Bool, num_senders)
        return new{T}(_data, _data_sent)
    end
end

function requestdata(c::DataChannel)
    c._data_sent .= false
end

function readdata(c::DataChannel)
    while !all(c.worker_done)
        busywait(0)
    end
    return true
end

function senddata!(c::DataContainer, data, id, term)
    while c.worker_done[id]
        busywait(0)
        term[] && return
    end


    offset = c.worker_offsets[id]
    for i in eachindex(data)
        c.data[i + offset] = data[i]
    end

    c.worker_done[id] = true
end


"""
    DataContainer{T,N}

A DataContainer stores some array data with type T and dimension N.
The workers that fill the data have their own indices for slicing the data
and a flag when they are done.
"""
struct DataContainer{T,N}
    data::Array{T,N}
    worker_indices::Vector{CartesianIndices{N,NTuple{N,UnitRange{Int64}}}}
    worker_done::Vector{Bool}
    function DataContainer(data, worker_indices)
        return new{typeof(data[1]),length(size(a))}(
            data,
            worker_indices,
            zeros(Bool, length(worker_indices))
        )
    end
end

isbusy(c::DataContainer) = all(c.send_done)

function requestdata(c::DataContainer)
    c.send_done .= false
end

copyto!(dest, c::DataContainer) = copyto!(dest, c.data)

function senddata!(c::DataContainer, data, id)
    copyto!(c.data[worker_indices[id]], data)
end