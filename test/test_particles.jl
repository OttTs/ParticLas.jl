@testset "particles" begin
    particles = ParticLas.AllocatedVector(ParticLas.Particle, 2)
    @test length(particles) == 0

    p = ParticLas.additem!(particles)
    p.position = ParticLas.Point2(1, 2)
    p = ParticLas.additem!(particles)
    p.position = ParticLas.Point2(3, 4)

    @test ParticLas.isfull(particles)
    @test ParticLas.maxlength(particles) == 2
    @test all(particles[1].position .== (1, 2))

    deleteat!(particles, 1)
    @test length(particles) == 1 && all(particles[1].position .== (3, 4))

    empty!(particles)
    @test length(particles) == 0
end
