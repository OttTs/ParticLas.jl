include("simulation/geometry.jl")
include("simulation/species.jl")
include("simulation/particles.jl")
include("simulation/statistics.jl")
include("simulation/wall.jl")
include("simulation/inflow.jl")
include("simulation/mesh.jl")
include("simulation/collision_operator.jl")
include("simulation/movement.jl")

function setup_simulation()
    mesh = Mesh(MESH_LENGTH)
    species = Species()
    time_step = 1E-6
    return mesh, species, time_step
end

function run_simulation!(particles, mesh, species, time_step, channel)
    while !data(channel,2).terminate
        if !data(channel,2).pause
            insert_particles!(particles, mesh, time_step)
            move_particles!(particles, mesh, time_step)
        end

        # We still calculate the relaxation parameters for visualization
        sum_up_particles!(particles, mesh)
        calculate_relaxation_parameters!(mesh, species, time_step)

        # Collision Step
        if data(channel,2).pause && data(channel,2).do_collisions
            relax_particles!(particles, mesh)
            sum_up_particles!(particles, mesh)
            enforce_conservation!(particles, mesh)
        end

        # Swap data and update simulation parameters
        send!(particles, mesh, data(channel,2))
        # TODO Stop time measurement
        swap!(channel, 2)
        # TODO Start time measurement
        update!(particles, mesh, species, data(channel,2))

    end
end

function send!(particles, mesh, data)
    if data.plot_type == :particles
        xₚ = particles.position
        x_visu = data.particle_positions
        @batch for i in eachindex(x_visu)
            j = (i - 1) * floor(Int, MAX_NUM_PARTICLES/NUM_PARTICLES_VISU) + 1
            x_visu[i] = xₚ[j]
        end
    elseif data.plot_type == :ρ
        data.mesh_values .= mesh.density
    elseif data.plot_type == :u
        for i in eachindex(mesh.bulk_velocity)
            data.mesh_values[i] = sqrt(sum(mesh.bulk_velocity[i].^2))
        end
    else # data.plot_type == :T
        data.mesh_values .= mesh.temperature
    end
end

function update!(particles, mesh, species, data)
    mesh.inflow_bc[] = InflowBC(data.inflow_density, data.inflow_velocity,
    INFLOW_TEMPERATURE,species)
    mesh.wall_bc[] = WallBC(WALL_TEMPERATURE, data.accomodation_coefficient, species)

    for points in data.new_walls
        add!(mesh, Wall(points...))
    end

    data.delete_walls && delete_walls!(mesh)
    data.delete_particles && empty!(particles)
end