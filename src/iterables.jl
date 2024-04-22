# TODO when looping, we need to minimize the number of checks!
# Array implementation: iterate(A::Array, i=1) = (@inline; (i % UInt) - 1 < length(A) ? (@inbounds A[i], i + 1) : nothing)
# Note: Recursive calls cannot be inlined!


#=
A list can contain a predefined maximum number of items.
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
mutable struct List{T}
    _items::Vector{T}
    _num_items::Int64
    List(T, max_length) = new{T}(zeros(T, max_length), 0)
end

function clear!(l::List)
    l._num_items = 0
end

Base.length(l::List) = l._num_items

function Base.push!(l::List{T}, item::T) where T
    l._num_items == length(l._items) && return -1
    l._num_items += 1
    l._items[l._num_items] = item
    return 1
end

function Base.delete!(l::List, index)
    # This also changes the ordering!
    (index % UInt) > length(l) && return -1
    l._items[index] = l._items[length(l)]
    l._num_items -= 1
end

Base.getindex(l::List, args...) = getindex(l._items, args...)

Base.eachindex(l::List) = reverse(1:l._num_items)

@inline function Base.iterate(l::List, i=1)
    return (i % UInt) - 1 < length(l) ? (@inbounds l._items[i], i + 1) : nothing
end

#=
A threaded list is a list where threads may need to access separate parts.
For example, in each cell, a threaded list of the particles is needed for each thread.
When performing the collision, however, the thread needs to access all particles.

# Example usage
> my_list = local_list(list, thread_id)

> for item in list
>     ...
> end
=#
struct ThreadedList{T}
    _items::Vector{List{T}}
    ThreadedList(T, max_length, num_threads) = new{T}(collect(List(T, max_length) for _ in 1:num_threads))
end

Base.length(tl::ThreadedList) = sum(length(l) for l in tl._items)

local_list(tl::ThreadedList, thread_id) = tl._items[thread_id]

@inline function Base.iterate(tl::ThreadedList, state=(1, 1))
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
    ThreadedMatrix(T, size, num_threads) = new{T}(zeros(T, size), num_threads)
end

Base.getindex(m::ThreadedMatrix, args...) = getindex(m._items, args...)

Base.setindex!(m::ThreadedMatrix, args...) = setindex!(m._items, args...)

local_items(m::ThreadedMatrix, thread_id) = @view(m._items[thread_id:m._num_threads:end])