#=
A threaded vector us a vector where threads may need to access separate parts.
For example, in each cell, a threaded vector of the particles is needed for each thread.
When performing the collision, however, the thread needs to access all particles.
=#
struct ThreadedVector{N,T}
    _items::NTuple{N,Vector{T}}
    function ThreadedList(T, num_threads)
        items = tuple((T[] for _ in 1:num_threads))
        for item in items
            sizehint!(item, 10^6)
        end
        return new{num_threads,T}(items)
    end
end

function clear!(tl::ThreadedVector)
    for l in tl._items
        clear!(l)
    end
end

Base.length(tl::ThreadedVector) = sum(length(l) for l in tl._items)

local_list(tl::ThreadedVector, thread_id) = tl._items[thread_id]

@inline function Base.iterate(tl::ThreadedVector, state=(1, 1))
    thread_id, index = state
    l = tl._items[thread_id]
    while (index % UInt) > length(l)
        thread_id += 1
        thread_id > length(tl._items) && return nothing
        l = tl._items[thread_id]
        index = 1
    end
    return (@inbounds l._items[index], (thread_id, index + 1))
end

#=
A ThreadedMatrix is used for the mesh cells.
The threads should handle the collision operator for their own cells.
Since each thread should ideally need to take the same amount of time,
the cells are assigned to each thread in a special way.

# Example usage
> item = m[i, j]

> for item in local_items(m, thread_id)
>     ...
> end
=#
struct ThreadedMatrix{T}
    _items::Matrix{T}
    _num_threads::Int64
    function ThreadedMatrix(item, size, num_threads)
        T = typeof(item)
        out = new{T}(Matrix{T}(undef, size), num_threads)
        for i in eachindex(out._items)
            out._items[i] = deepcopy(item)
        end
        return out
    end
end

Base.getindex(m::ThreadedMatrix, args...) = getindex(m._items, args...)

Base.size(m::ThreadedMatrix) = size(m._items)

local_indices(m::ThreadedMatrix, thread_id) = thread_id:m._num_threads:length(m._items)

local_items(m::ThreadedMatrix, thread_id) = @view(m._items[local_indices(m, thread_id)])

Base.iterate(m::ThreadedMatrix) = iterate(m._items)
