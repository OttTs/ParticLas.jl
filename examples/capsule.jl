# TODO relative position towards the center?
function draw_capsule()
    pts = Point2f[]
    ϕₘₐₓ = 40 / 180 * π
    r = 0.14
    for ϕ in range(-ϕₘₐₓ, ϕₘₐₓ; length=1000)
        push!(pts, Point2f(0.7 + r * (0.6 - cos(ϕ)), 0.5 + r * sin(ϕ)))
    end
    push!(pts, Point2f(0.75, 0.53))
    push!(pts, Point2f(0.75, 0.47))
    push!(pts, Point2f(0.7 + r * (0.6 - cos(-ϕₘₐₓ)), 0.5 + r * sin(-ϕₘₐₓ)))
    return pts
end
object_points = draw_capsule()
