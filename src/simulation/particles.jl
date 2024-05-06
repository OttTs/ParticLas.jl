#=
A particle is defined by its 2D position and its 3D velocity.
Since particle operations are the most time critical, the position of the particle
inside the mesh (index) is explicitly stored.
=#
mutable struct Particle
    position::Point2{Float64}
    velocity::Vec3{Float64}
    index::CartesianIndex{2}
end

Base.zero(::Type{T}) where {T<:Particle} = Particle(
    zero(Point2{Float64}), zero(Vec3{Float64}), zero(CartesianIndex{2})
)

#=
The thread-local particle vectors are preallocated with their maximum number of particles.
For this, a type "AllocatedVector" is defined.
=#
mutable struct AllocatedVector{T} <: AbstractVector{T}
    _items::Vector{T}
    _num_items::Int64
    AllocatedVector(T, max_length) = new{T}(zeros(T, max_length), 0)
end

Base.size(v::AllocatedVector) = (v._num_items,)
Base.getindex(v::AllocatedVector, i) = v._items[i]
Base.eachindex(v::AllocatedVector) = (@inline(); reverse(1:length(v)))
Base.iterate(v::AllocatedVector, i=1) =
    (@inline; (i % UInt) - 1 < length(v) ? (@inbounds v[i], i + 1) : nothing)

maxlength(v::AllocatedVector) = length(v._items)
isfull(v::AllocatedVector) = (length(v) >= maxlength(v))

function additem!(v::AllocatedVector)
    v._num_items += 1
    return v._items[v._num_items]
end

function Base.deleteat!(v::AllocatedVector, index)
    v._items[index] = v._items[v._num_items]
    v._num_items -= 1
end



