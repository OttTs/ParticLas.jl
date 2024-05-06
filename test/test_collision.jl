@testset "Collisions" begin
    species = ParticLas.Species(1E21, 6.63E-26, 273, 0.77; ref_diameter=4.05E-10)
    # Add 10000 random particles
    particles = ParticLas.AllocatedVector(ParticLas.Particle, 10^6)
    for i in 1:10000
        p = ParticLas.additem!(particles)
        p.position = (0, 0)
        p.velocity = (randn(), randn(), randn())
        p.index = CartesianIndex(1, 1)
    end

    # Set the mean and variance for the particles
    mesh = ParticLas.Mesh((1, 1), (1, 1))
    mesh.cells[1,1].bulk_velocity = ParticLas.Vec{3, Float64}(100, 200, 300)
    mesh.cells[1,1].scale_parameter = 1E3
    ParticLas.sum_up_particles!(particles, mesh, 1)
    ParticLas.conservation_parameters!(mesh, 1)
    ParticLas.conservation_step!(particles, mesh)

    ParticLas.sum_up_particles!(particles, mesh, 1)
    N, u, σ² = ParticLas.calculate_moments(mesh.cells[1,1].raw_moments)
    @test N == length(particles)
    @test u ≈ mesh.cells[1,1].bulk_velocity
    @test σ² ≈ mesh.cells[1,1].scale_parameter^2

    # test relaxation...
    Δt = 1E-9
    ρ = species.weighting * species.mass * N
    T = ParticLas.temperature(σ², species)
    P = ParticLas.collision_probability(ρ, T, Δt, species)
    mesh.cells[1,1].bulk_velocity = u
    mesh.cells[1,1].relaxation_probability = P
    mesh.cells[1,1].scale_parameter = √σ²
    ParticLas.relax_particles!(particles, mesh)
    ParticLas.sum_up_particles!(particles, mesh, 1)
    N, u, σ² = ParticLas.calculate_moments(mesh.cells[1,1].raw_moments)
    @test isapprox(N, length(particles); rtol=0.1)
    @test isapprox(u, mesh.cells[1,1].bulk_velocity; rtol=0.1)
    @test isapprox(σ², mesh.cells[1,1].scale_parameter^2; rtol=0.1)
end