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