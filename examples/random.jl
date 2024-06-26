# Random points
function draw_random()
    pts = Point2f[]
    for i in 1:10
        φ = 2π * i / 10
        r = rand() * 0.3
        push!(pts, Point2f(0.7 + r * cos(φ), 0.5 + r * sin(φ)))
    end
    push!(pts, pts[1])
    return pts
end
object_points = draw_random()
