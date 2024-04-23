@testset "particles" begin
    a = ParticLas.Particle((1,2), (3,4,5))
    b = zero(ParticLas.Particle)
    ParticLas.copy!(b, a)
    @test (b.position == a.position && b.velocity == a.velocity)
end
