
struct Line
    point::Point2{Float64}
    vector::Vec2{Float64}
    Line(p1::Point2, p2::Point2) = new(p1, Vec(p2 - p1))
    Line(p::Point2, v::Vec2) = new(p, v)
end

points(l::Line) = (l.point, l.point + l.vector)
pointfrom(l::Line) = l.point
pointto(l::Line) = l.point + l.vector

function intersect(a::Line, b::Line)::Union{Nothing, Float64}
    (a.vector × b.vector) == 0 && return nothing
    t = (b.point × a.vector - a.point × a.vector) / (a.vector × b.vector)
    (t < 0 || t > 1) && return nothing
    u = (b.point × b.vector - a.point × b.vector) / (a.vector × b.vector)
    (u < 0 || u > 1) && return nothing
    return u
end