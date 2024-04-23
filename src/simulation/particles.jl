#=
A particle is defined by its 2D positio and its 3D velocity.
Since particle operations are the most time critical, the position of the particle
inside the mesh (index) is explicitly stored.
=#
mutable struct Particle
    position::Point2{Float64}
    velocity::Vec3{Float64}
end

function Base.zero(::Type{T}) where {T<:Particle}
    return Particle(zero(Point2{Float64}), zero(Vec3{Float64}))
end

function Base.copy!(dst::Particle, src::Particle)
    dst.position = src.position
    dst.velocity = src.velocity
end