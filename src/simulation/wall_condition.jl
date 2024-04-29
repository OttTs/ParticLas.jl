mutable struct WallCondition
    most_probable_velocity::Float64
    accomodation_coefficient::Float64
    WallCondition() = new(0, 0)
end

function set_accomodation_coefficient!(w::WallCondition, acc)
    w.accomodation_coefficient = acc
end

function set_temperature!(w::WallCondition, t; species)
    w.most_probable_velocity = √(2 * BOLTZMANN_CONST * t / species.mass)
end
