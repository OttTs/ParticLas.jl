mutable struct MyLinkedListItem{T}
    _item::T
    _next::Union{MyLinkedListItem{T}, Nothing}
    MyLinkedListItem(T) = new{T}(zero(T), nothing)
end

mutable struct MyLinkedList{T}
    _first_item::Union{MyLinkedListItem{T}, Nothing}
    _first_free_item::Union{MyLinkedListItem{T}, Nothing}
    function MyLinkedList(T, max_lengh)
        first = MyLinkedListItem(T)
        for _ in 1:max_lengh-1
            first._next = MyLinkedListItem(T)
            first = first._next
        end
        return new{T}(nothing, first)
    end
end

function Base.push!(v::MyLinkedList{T}, item::T) where T
    isnothing(_first_free_item) && return -1
    bucket = v._first_free_item
    v._first_free_item = bucket._next
    v._num_items += 1
    v._items[v._num_items] = item
    return nothing
end


mutable struct MyArray{T}