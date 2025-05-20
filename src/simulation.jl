include("simulation/geometry.jl")
include("simulation/species.jl")
include("simulation/particles.jl")
include("simulation/statistics.jl")
include("simulation/wall.jl")
include("simulation/inflow.jl")
include("simulation/mesh.jl")
include("simulation/collision_operator.jl")
include("simulation/movement.jl")

function run_simulation(particles, mesh, species, time_step, channel)
    t1 = frametime()
    while !data(channel,2).terminate
        if !data(channel,2).pause
            insert_particles!(particles, mesh, time_step)
        end
        t21 = frametime()
        if !data(channel,2).pause
            # TODO This is quite slow
            # With batch only: 0.4
            move_particles!(particles, mesh, time_step)
        end
        t2 = frametime()

        # We still calculate the relaxation parameters for visualization
        sum_up_particles!(particles, mesh)
        calculate_relaxation_parameters!(mesh, species, time_step)
        t3 = frametime()
        # Collision Step
        if !data(channel,2).pause && data(channel,2).do_collisions
            relax_particles!(particles, mesh)
            sum_up_particles!(particles, mesh)
            enforce_conservation!(particles, mesh)
        end
        t4 = frametime()

        # Swap data and update simulation parameters
        send!(particles, mesh, data(channel,2))
        # TODO Stop time measurement
        open("sim.time", "w") do io
            write(io, "$(round(frametime() - t1; digits=2))\n
                       $(round(t21 - t1; digits=2))\n
                       $(round(t2 - t21; digits=2))\n
                       $(round(t3 - t2; digits=2))\n
                       $(round(t4 - t3; digits=2))")
        end
        swap!(channel, 2) # TODO uncomment
        # TODO Start time measurement
        t1 = frametime()
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
        for i in eachindex(mesh.velocity)
            data.mesh_values[i] = sqrt(sum(mesh.velocity[i].^2))
        end
    else # data.plot_type == :T
        data.mesh_values .= mesh.temperature
    end
end

function update!(particles, mesh, species, data)
    mesh.inflow_bc[] = InflowBC(data.inflow_density, data.inflow_velocity, INFLOW_TEMPERATURE, species)
    mesh.wall_bc[] = WallBC(WALL_TEMPERATURE, data.accomodation_coefficient, species)

    for points in data.new_walls
        add!(mesh, Wall(points...))
    end

    data.delete_walls && delete_walls!(mesh)
    data.delete_particles && empty!(particles)
end