mutable struct GUIData
    display_particles::Observable{Bool}
    mesh_values::Observable{Matrix{Float32}}
    particle_points::Observable{Vector{Point2f}}
    wall_points::Observable{Vector{Point2f}}

    terminate::Bool
    pause::Bool

    plot_type::Symbol
    inflow_altitude::Float64
    inflow_velocity::Float64

    new_wall::NTuple{2, Point2f}
    accomodation_coefficient::Float64

    delete_walls::Bool
    delete_particles::Bool

    screen::GLMakie.Screen{GLFW.Window}

    function GUIData()
        wall_points = Observable(Point2f[])
        sizehint!(wall_points[], 10^6)
        return new(
            Observable(true),
            Observable(zeros(NUM_CELLS)),
            Observable(Point2f[]),
            wall_points,
            false,
            true,
            :particles,
            DEFAULT_ALTITUDE,
            DEFAULT_VELOCITY,
            (Point2{Float64}(NaN), Point2{Float64}(NaN)),
            DEFAULT_ACCOMODATION_COEFFICIENT,
            false,
            false
        )
    end
end

include("gui/setup.jl")
include("gui/renderloop.jl")


