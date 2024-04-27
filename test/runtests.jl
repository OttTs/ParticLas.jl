using ParticLas
using Test
using Statistics: mean, var

@testset "ParticLas.jl" begin
    include("test_particles.jl")
    include("test_iterables.jl")
    include("test_geometry.jl")
    include("test_statistics.jl")
    include("test_collision.jl")
end
