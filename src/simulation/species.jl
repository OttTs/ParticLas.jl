struct Species
    weighting::Float64
    mass::Float64
    ref_temperature::Float64
    ref_viscosity::Float64
    ref_exponent::Float64

    function Species()
        μᵣ = reference_viscosity(MASS, REF_TEMP, REF_DIA, REF_EXP)
        return new(WEIGHTING, MASS, REF_TEMP, μᵣ, REF_EXP)
    end
end

function reference_viscosity(mₛ, Tᵣ, dᵣ, ω)
    return 30 * √(mₛ * BOLTZMANN_CONST * Tᵣ / π) / (4 * (5 - 2 * ω) * (7 - 2 * ω) * dᵣ^2)
end