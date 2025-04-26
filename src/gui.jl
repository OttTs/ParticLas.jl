mutable struct GUI
    terminate::Bool
    pause::Bool
    delete_walls::Bool
    delete_particles::Bool
    do_collisions::Bool
    plot_type::Observable{Symbol}
    inflow_altitude::Float64 # TODO change to inflow_density
    inflow_velocity::Float64
    accomodation_coefficient::Float64
    new_walls::Vector{NTuple{2, Point2f}}
    particle_points::Vector{Point2f}
    mesh_values::Matrix{Float32}
    wall_points::Observable{Vector{Point2f}}
    resolution::NTuple{2, Int64}
    screen::GLMakie.Screen{GLFW.Window}

    function GUI()
        new_walls = NTuple{2, Point2f}[]
        sizehint!(new_walls, 1000)
        particle_points = zeros(Point2f, MAX_NUM_PARTICLES_VISU)
        mesh_values = zeros(Float32, NUM_CELLS)
        wall_points = Observable(Point2f[])
        sizehint!(wall_points[], 1000000)
        return new(
            false, true, false, false, true,
            Observable{Symbol}(:particles),
            DEFAULT_ALTITUDE, DEFAULT_VELOCITY, DEFAULT_ACCOMODATION_COEFFICIENT,
            new_walls, particle_points, mesh_values, wall_points
        )
    end
end

include("gui/blocks.jl")
include("gui/drawing.jl")
include("gui/initialize.jl")
include("gui/renderloop.jl")


