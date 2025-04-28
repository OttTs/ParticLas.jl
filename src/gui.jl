mutable struct GUI
    terminate::Bool
    pause::Bool
    delete_walls::Bool
    delete_particles::Bool
    do_collisions::Bool
    plot_type::Observable{Symbol}
    inflow_density::Float64
    inflow_velocity::Float64
    accomodation_coefficient::Float64
    new_walls::Vector{NTuple{2, Point2f}}
    particle_points::Observable{Vector{Point2f}}
    mesh_values::Observable{Matrix{Float32}}
    display_scaling::NTuple{2, Float64}
    resolution::NTuple{2, Int64}
    screen::GLMakie.Screen{GLFW.Window}

    function GUI()
        new_walls = NTuple{2, Point2f}[]
        sizehint!(new_walls, 1000)
        particle_points = Observable(zeros(Point2f, NUM_PARTICLES_VISU))
        mesh_values = Observable(zeros(Float32, NUM_CELLS))
        return new(
            false, true, false, false, true,
            Observable{Symbol}(:particles),
            1.225 * exp(-0.11856 *DEFAULT_ALTITUDE) , DEFAULT_VELOCITY, DEFAULT_ACCOMODATION_COEFFICIENT,
            new_walls, particle_points, mesh_values
        )
    end
end

include("gui/blocks.jl")
include("gui/drawing.jl")
include("gui/initialize.jl")
include("gui/renderloop.jl")


