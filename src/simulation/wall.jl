struct Wall
    normal::Vec2{Float64}
    line::Line
    function Wall(a, b)
        v = Vec(b .- a)
        normal = Vec(-v[2], v[1]) / norm(v)
        return new(normal, Line(Point2{Float64}(a), v))
    end
    function Wall()
        return new(zero(Vec2{Float64}), Line(zero(Point2{Float64}), zero(Vec2{Float64})))
    end
end

struct WallBC
    most_probable_velocity::Float64
    accomodation_coefficient::Float64

    WallBC(T, α, species) = new(√(2 * BOLTZMANN_CONST * T / species.mass), α)
end