using GLMakie: Point2, Point3

@testset "particles" begin
    a = ParticLas.Particle(Point2{Float64}(1,2), Point3{Float64}(3,4,5), Point2{Int}(6,7))
    b = ParticLas.Particle(Point2{Float64}(0,0), Point3{Float64}(0,0,0), Point2{Int}(0,0))
    ParticLas.copy!(b, a)
    @test (b.position == a.position && b.velocity == a.velocity && b.index == a.index)
    b.position = Point2{Float64}(0,0)

    pd = ParticLas.ParticleData(2)
    ParticLas.add!(pd, b)
    @test pd[1] === b
    @test !ParticLas.isfull(pd)

    ParticLas.add!(pd, a)
    @test ParticLas.isfull(pd)

    ParticLas.remove!(pd, 1)
    @test pd[1].position == a.position

    ParticLas.reset!(pd)
    @test pd.num_particles == 0
end
