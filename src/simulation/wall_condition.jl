mutable struct WallCondition
    most_probable_velocity::Float64
    accomodation_coefficient::Float64
    WallCondition() = new(0, 0)
end

function set!(c::WallCondition, accomodation_coefficient, species)
    temperature = 600 # TODO wall temperature
    c.most_probable_velocity = √(2 * BOLTZMANN_CONST * temperature / species.mass)
    c.accomodation_coefficient = accomodation_coefficient
end