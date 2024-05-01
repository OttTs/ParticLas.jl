function sample_inflow_velocity(most_probable_velocity, velocity=0)
    zs = samplezs(velocity / most_probable_velocity)
    return Vec3(
        velocity - zs * most_probable_velocity,
        √0.5 * most_probable_velocity * randn(),
        √0.5 * most_probable_velocity * randn()
    )
end

stochastic_round(x) = (rand() > x - floor(x)) ? floor(Int64, x) : ceil(Int64, x)

function samplezs(a::Number)
    # Samples the random variable zs with a given speed ratio a
    # See "Garcia and Wagner - 2006 - Generation of the Maxwellian inflow distribution"
    if a < -0.4
        z = 0.5*(a - √(a^2+2))
        β = a - (1 - a) * (a - z)
        while true
            if exp(-β^2) / (exp(-β^2) + 2 * (a - z) * (a - β) * exp(-z^2)) > rand()
                zs = -√(β^2 - log(rand()))
                (zs - a) / zs > rand() && return zs
            else
                zs = β + (a - β) * rand()
                (a - zs) / (a - z) * exp(z^2 - zs^2) > rand() && return zs
            end
        end
    elseif a < 0
        while true
            zs = -√(a^2 - log(rand()))
            (zs - a) / zs > rand() && return zs
        end
    elseif a == 0
        return -√(-log(rand()))
    elseif a < 1.3
        while true
            u = rand()
            a * √π / (a * √π + 1 + a^2) > u && return -1/√2 * abs(randn())
            (a * √π + 1) / (a * √π + 1 + a^2) > u && return -√(-log(rand()))
            zs = (1 - √rand()) * a
            exp(-zs^2) > rand() && return zs
        end
    else # a > 1.3
        while true
            if 1 / (2 * a * √π + 1) > rand()
                zs = -√(-log(rand()))
            else
                zs = 1 / √2 * randn()
            end
            (a - zs) / a > rand() && return zs
        end
    end
end