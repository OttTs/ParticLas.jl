@testset "statistics" begin
    σ = rand()
    samples = [ParticLas.sample_inflow_velocity(√2 * σ) for i in 1:10^5]
    @test isapprox(mean(samples), ParticLas.Vec(σ * √(π / 2), 0, 0); atol=1E-2)
    @test isapprox(var(samples), ParticLas.Vec((4 - π) / 2 * σ^2, σ^2, σ^2); atol=1E-2)

    x = rand()
    @test isapprox(mean([ParticLas.stochastic_round(x) for i in 1:10^5]), x; atol=1E-2)
end