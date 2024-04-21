#=
A particle is defined by its 2D positio and its 3D velocity.
Since particle operations are the most time critical, the position of the particle
inside the mesh (index) is explicitly stored.
=#
mutable struct Particle
    position::Point2{Float64}
    velocity::Point3{Float64}
    index::Point2{Int} # TODO Should be a Cartesian Index!
end

function Base.zero(::Type{T}) where {T<:Particle}
    return Particle(Point2{Float64}(0,0), Point3{Float64}(0,0,0), Point2{Int}(0,0))
end

function Base.copy!(dst::Particle, src::Particle)
    dst.position = src.position
    dst.velocity = src.velocity
    dst.index = src.index
end

#=
Struct for managing the list of particles.
In order to avoid allocations during the simulations, a long vector "particles"
is allocated and "num_particles" is used to keep track of the numer of particles
in the simulation.
=#
mutable struct ParticleData
    num_particles::Int64
    particles::Vector{Particle}
    ParticleData(num_particles) = new(0, zeros(Particle, num_particles))
end

function Base.getindex(pd::ParticleData, i::Int64)
    return pd.particles[i]
end

function isfull(pd::ParticleData)
    return pd.num_particles >= length(pd.particles)
end

function add!(pd::ParticleData, p::Particle)
    pd.num_particles += 1
    pd.particles[pd.num_particles] = p
end

function remove!(pd::ParticleData, i::Int64)
    copy!(pd.particles[i], pd.particles[pd.num_particles])
    pd.num_particles -= 1
end

function reset!(pd::ParticleData)
    pd.num_particles = 0
end