using ParticLas
using Test

@testset "ParticLas.jl" begin
    include("test_particles.jl")
    include("test_mesh.jl")
end
