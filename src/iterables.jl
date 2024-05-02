#=
A list can contain a predefined maximum number of (preallocated) items.
A standard array cannot be used since the mutable type may still be allocated!
# Example Usage:
> push!(list, item)

> for i in eachindex(list)
>     item = list[i]
>     ...
>     delete(list, i)
> end

> for item in list
>     ...
> end
=#
mutable struct AllocatedVector{T}
    _items::Vector{T}
    _num_items::Int64
    AllocatedVector(T, max_length) = new{T}([zero(T) for i in 1:max_length], 0)
end

function Base.empty!(v::AllocatedVector)
    v._num_items = 0
end

isfull(v::AllocatedVector) = v._num_items >= length(v._items)

Base.length(v::AllocatedVector) = v._num_items

function Base.push!(v::AllocatedVector{T}, item::T) where T
    v._num_items >= length(v._items) && return -1
    v._num_items += 1
    v._items[v._num_items] = item
    return 1
end

function add!(v::AllocatedVector)
    v._num_items += 1
    return v._items[v._num_items]
end

function Base.deleteat!(v::AllocatedVector, index)
    # This also changes the ordering!
    (index % UInt) > length(v) && return -1

    copy!(v._items[index], v._items[v._num_items])
    #v._items[index] = v._items[v._num_items]
    v._num_items -= 1
end

Base.getindex(v::AllocatedVector, args...) = getindex(v._items, args...)

Base.eachindex(v::AllocatedVector) = reverse(1:v._num_items)

@inline function Base.iterate(v::AllocatedVector, i=1)
    return (i % UInt) - 1 < length(v) ? (@inbounds v._items[i], i + 1) : nothing
end

#=
A threaded vector us a vector where threads may need to access separate parts.
For example, in each cell, a threaded vector of the particles is needed for each thread.
When performing the collision, however, the thread needs to access all particles.
=#
struct ThreadedVector{T}
    _items::Vector{AllocatedVector{T}}
    function ThreadedVector(T, max_length_per_thread, num_threads)
        return new{T}(collect(AllocatedVector(T, max_length_per_thread) for _ in 1:num_threads))
    end
end

function Base.empty!(tl::ThreadedVector)
    for item in tl._items
        empty!(item)
    end
end

Base.length(tl::ThreadedVector) = sum(length(l) for l in tl._items)

local_vector(tl::ThreadedVector, thread_id) = tl._items[thread_id]

@inline function Base.iterate(tl::ThreadedVector, state=(1, 1))
    thread_id, index = state
    l = tl._items[thread_id]
    while (index % UInt) > length(l)
        thread_id += 1
        thread_id > length(tl._items) && return nothing
        l = tl._items[thread_id]
        index = 1
    end
    return (@inbounds l[index], (thread_id, index + 1))
end

#=
A ThreadedMatrix is used for the mesh cells.
The threads should handle the collision operator for their own cells.
Since each thread should ideally need to take the same amount of time,
the cells are assigned to each thread in a special way.

# Example usage
> item = m[i, j]

> for i in local_indices(m, thread_id)
>     ...
> end
=#
struct ThreadedMatrix{T}
    _items::Matrix{T}
    _num_threads::Int64
    function ThreadedMatrix(T, size, num_threads; args=())
        out = new{T}(Matrix{T}(undef, size), num_threads)
        for i in eachindex(out._items)
            out._items[i] = zero(T, args...)
        end
        return out
    end
end

Base.getindex(m::ThreadedMatrix, args...) = getindex(m._items, args...)

Base.size(m::ThreadedMatrix) = size(m._items)

local_indices(m::ThreadedMatrix, thread_id) = thread_id:m._num_threads:length(m._items)

Base.iterate(m::ThreadedMatrix) = iterate(m._items)
