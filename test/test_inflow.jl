@testset "Inflow" begin
    particles = ParticLas.AllocatedVector(ParticLas.Particle, 10^5)
    species = ParticLas.Species(2E16, 6.63E-26, 273, 0.77; ref_diameter=4.05E-10)
    inflow = ParticLas.InflowCondition()
    ParticLas.set!(inflow, 1.225, 100, 273, species)

    @test inflow.velocity == 100
    @test inflow.most_probable_velocity ≈ 337.1950561356927
    @test inflow.number_flux ≈ 187.8738215686097 / (species.mass * species.weighting)

    mesh = ParticLas.Mesh((1,1), (100, 100))
    ParticLas.set!(mesh.inflow_condition, 1.225, 100, 273, species)

    Δt = 10^-7
    ParticLas.insert_particles!(particles, mesh, Δt)

    num_new = mesh.inflow_condition.number_flux * Δt / Threads.nthreads(:default)
    @test isapprox(length(particles), num_new, atol=1)

    @test all(p.velocity[1] > 0 for p in particles)



    #@test ParticLas.pointfrom(a) == ParticLas.Point2(1, 5)
    #@test ParticLas.pointto(a) == ParticLas.Point2(-4, -10)
    #@test ParticLas.intersect(a, b) == 0.8
    #@test isnothing(ParticLas.intersect(a, c))
end