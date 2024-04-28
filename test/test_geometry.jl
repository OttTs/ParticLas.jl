@testset "geometry" begin
    a = ParticLas.Line(ParticLas.Point2(1, 5), ParticLas.Point2(-4, -10))
    b = ParticLas.Line(ParticLas.Point2(0, -1), ParticLas.Vec2(-3.5, -7))
    c = ParticLas.Line(ParticLas.Point2(0, -1), ParticLas.Vec2(-2.5, -5))

    @test ParticLas.pointfrom(a) == ParticLas.Point2(1, 5)
    @test ParticLas.pointto(a) == ParticLas.Point2(-4, -10)
    @test ParticLas.intersect(a, b) == 0.8
    @test isnothing(ParticLas.intersect(a, c))
end