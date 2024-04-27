@testset "Collisions" begin
    species = ParticLas.Species(1E16, 6.63E-23, 273, 0.77; ref_diameter=4.05E-10)
    # Add 1000 random particles
    particles = ParticLas.ThreadedList(ParticLas.Particle, 1000, 2)
    for id in 1:2
        local_particles = ParticLas.local_list(particles, id)
        for i in 1:500
            push!(local_particles, ParticLas.Particle((0, 0), (randn(), randn(), randn())))
        end
    end
    # Set the mean and variance for the particles
    target_mean = ParticLas.Vec{3, Float64}(100, 200, 300)
    target_variance = 1000
    time_step = 1E-6
    ParticLas.conservation_step!(particles, target_mean, target_variance)

    N, u, σ² = ParticLas.sample_moments(particles)
    @test N == length(particles)
    @test u ≈ target_mean
    @test σ² ≈ target_variance

    # test relaxation...
    ρ = species.weighting * species.mass * N
    T = ParticLas.temperature(σ², species)
    P = ParticLas.collision_probability(ρ, T, time_step, species)
    println(P)
    ParticLas.relax!(particles, P, u, √(σ²))
    N, u, σ² = ParticLas.sample_moments(particles)
    @test isapprox(N, length(particles); atol=1)
    @test isapprox(u, target_mean; atol=1)
    @test isapprox(σ², target_variance; atol=1)
end