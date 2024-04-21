#=
Moments of the velocity distribution in each cell.
    0. particle number N
    1. bulk velocity
    2. variance
=#
function bulk_velocity(N, ∑v¹)
    N == 0 && return 0
    return ∑v¹ / N
end

function velocity_variance(N, ∑v¹, ∑v²)
    N < 2 && return 0
    ∑c² = ∑v² - sum(∑v¹⋅∑v¹) / N
    return ∑c² / (3 * (N - 1))
end

#=
Physical macroscopic variables.
    0. density
    1. bulk velocity (same as the 1. moment)
    2. temperature
=#
function density(N, mₛ, ω, mesh)
    return N * ω * mₛ / cell_volume(mesh)
end

function temperature(σ², mₛ)
    return σ² * mₛ / BOLTZMANN_CONST
end

#=
Variables for the BGK collision operator
    - Collision probability: Probability for each particle to relax

Sampling from the target distribution is done using
    - bulk velocty (same as the 1. moment)
    - standard deviation: square root of velocity variance
=#
function collision_probability(density, temperature, species, time_step)
    ν = relaxation_frequency(density, temperature, species)
    return time_step * ν
end

function relaxation_frequency(ρ, T, species)
    μ = dynamic_viscosity(T, species)
    return ρ * BOLTZMANN_CONST * T / (μ * species.mass)
end

function dynamic_viscosity(T, species)
    return species.ref_viscosity * (T / species.ref_temperature)^species.ref_exponent
end

#=
Variables for momentum and energy conservation
    - scale_ratio: sqrt(target_temperature / current_temperature)
    - bulk_velocity
    - new_bulk_velocity
=#
function scale_ratio(N, ∑vₙ¹, ∑vₙ², T, mₛ)
    T == 0 && return 0
    σₙ² = velocity_variance(N, ∑vₙ¹, ∑vₙ²)
    Tₙ = temperature(σₙ², mₛ)
    return √(T / Tₙ)
end