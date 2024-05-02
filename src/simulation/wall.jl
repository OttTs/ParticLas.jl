struct Wall
    normal::Vec3{Float64}
    line::Line
    function Wall(a, b)
        v = Vec(b .- a)
        normal = Vec(-v[2], v[1], 0) / norm(v)
        return new(normal, Line(Point2{Float64}(a), v))
    end
end

Base.zero(::Type{T}) where {T<:Wall} = Wall(zero(Point2f), zero(Point2f))

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