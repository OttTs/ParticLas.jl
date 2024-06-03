# TODO relative position towards the center?
object_points = Point2f[]
ϕₘₐₓ = 20 / 180 * π
r = 0.4
for ϕ in range(-ϕₘₐₓ, ϕₘₐₓ; length=10)
    push!(object_points, Point2f(0.7 + r * (0.6 - cos(ϕ)), 0.5 + r * sin(ϕ)))
end
push!(object_points, Point2f(0.7, 0.55))
push!(object_points, Point2f(0.7, 0.45))
push!(object_points, Point2f(0.7 + r * (0.6 - cos(-ϕₘₐₓ)), 0.5 + r * sin(-ϕₘₐₓ)))