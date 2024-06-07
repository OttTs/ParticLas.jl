# TODO relative position towards the center?
function draw_capsule()
    pts = Point2f[]
    ϕₘₐₓ = 20 / 180 * π
    r = 0.4
    for ϕ in range(-ϕₘₐₓ, ϕₘₐₓ; length=10)
        push!(pts, Point2f(0.7 + r * (0.6 - cos(ϕ)), 0.5 + r * sin(ϕ)))
    end
    push!(pts, Point2f(0.68, 0.55))
    push!(pts, Point2f(0.68, 0.45))
    push!(pts, Point2f(0.7 + r * (0.6 - cos(-ϕₘₐₓ)), 0.5 + r * sin(-ϕₘₐₓ)))
    return pts
end
object_points = draw_capsule()
