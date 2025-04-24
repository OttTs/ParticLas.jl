struct Particles
    position::Vector{Point2{Float64}}
    velocity::Vector{Vec3{Float64}}
    index::Vector{CartesianIndex{2}}
    free_indices::Vector{Int64} # Used to insert new particles

    Particles() = new(
        Vector{Point2{Float64}}(undef, MAX_NUM_PARTICLES),
        Vector{Vec3{Float64}}(undef, MAX_NUM_PARTICLES),
        [CartesianIndex(-1, -1) for _ in 1:MAX_NUM_PARTICLES],
        Vector{Int64}(undef, MAX_NUM_PARTICLES)
    )
end

function empty!(p::Particle)
    indices = p.index
    @batch for i in eachindex(indices)
        p.index[i] = CartesianIndex(-1, -1)
    end
end