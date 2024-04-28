struct Species
    weighting::Float64
    mass::Float64
    ref_temperature::Float64
    ref_viscosity::Float64
    ref_exponent::Float64
end

function Species(weighting, mass, ref_temperature, ref_exponent; ref_diameter)
    μᵣ = reference_viscosity(mass, ref_temperature, ref_diameter, ref_exponent)
    return Species(weighting, mass, ref_temperature, μᵣ, ref_exponent)
end

function reference_viscosity(mₛ, Tᵣ, dᵣ, ω)
    return 30 * √(mₛ * BOLTZMANN_CONST * Tᵣ / π) / (4 * (5 - 2 * ω) * (7 - 2 * ω) * dᵣ^2)
end