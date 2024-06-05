function draw_circle()
    pts = Point2f[]
    for i in 1:1000
        φ = 2π * i / 1000
        r = 0.1
        push!(pts, Point2f(0.6 + r * cos(φ), 0.5 + r * sin(φ)))
    end
    push!(pts, pts[1])
    return pts
end
object_points = draw_circle()
