#=
A particle is defined by its 2D position and its 3D velocity.
Since particle operations are the most time critical, the position of the particle
inside the mesh (index) is explicitly stored.
=#

struct Particles
    position::Vector{Point2{Float64}}
    velocity::Vector{Vec3{Float64}}
    index::Vector{CartesianIndex{2}}
    inside::Vector{Bool}
    Particles(max_num) = new(
        zeros(Point2{Float64}, max_num),
        zeros(Vec3{Float64}, max_num),
        zeros(CartesianIndex{2}, max_num),
        zeros(Bool, max_num)
    )
end

Base.eachindex(p::Particles) = eachindex(p.index)

function Base.empty!(p::Particles)
    @batch for i in eachindex(p.inside)
        p.inside[i] = 0
    end
end


#=
mutable struct Particle
    position::Point2{Float64}
    velocity::Vec3{Float64}
    index::CartesianIndex{2}
end

Base.zero(::Type{T}) where {T<:Particle} = Particle(
    zero(Point2{Float64}), zero(Vec3{Float64}), zero(CartesianIndex{2})
)

function Base.copy!(dst::Particle, src::Particle)
    dst.position = src.position
    dst.velocity = src.velocity
    dst.index = src.index
end

#=
The thread-local particle vectors are preallocated with their maximum number of particles.
For this, a type "AllocatedVector" is defined.
=#
mutable struct AllocatedVector{T} <: AbstractVector{T}
    _items::Vector{T}
    _num_items::Int64
    AllocatedVector(T, max_length) = new{T}([zero(T) for _ in 1:max_length], 0)
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
    copy!(v._items[index], v._items[v._num_items])
    v._num_items -= 1
end

Base.empty!(v::AllocatedVector) = (@inline; v._num_items = 0)

=#