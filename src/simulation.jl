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
    mesh = Mesh(MESH_LENGTH, NUM_CELLS)
    species = Species(2E16, 6.63E-26, 273, 0.77; ref_diameter=4.05E-10)
    time_step = 1E-6
    return mesh, species, time_step
end

function simulation_thread(particles, mesh, species, time_step, channel)
    # todo inflow and wall_condition is in mesh
    while !simdata(channel).terminate
        if !simdata(channel).pause
            timing = simdata(channel).timing_data
            timing.sim_start = frametime()

            #------------------------------------------------------------------------------
            # Movement Step
            insert_particles!(particles, mesh, time_step)
            timing.pure_insertion = frametime()
            movement_step!(particles, mesh, time_step)
            timing.pure_movement = frametime()
            sum_up_particles!(particles, mesh)
            timing.sync = frametime()
            timing.movement = frametime()
            #------------------------------------------------------------------------------
            # Collision Step
            relaxation_parameters!(mesh, species, time_step)
            timing.relax_parameters = frametime()
            relax_particles!(particles, mesh)
            sum_up_particles!(particles, mesh)
            timing.relax = frametime()
            conservation_parameters!(mesh)
            timing.conservation_parameters = frametime()
            conservation_step!(particles, mesh)
            timing.conservation = frametime()
            #------------------------------------------------------------------------------
        end

        send_data!(particles, mesh, channel)

        simdata(channel).delete_walls && delete_walls!(mesh)

        swap!(channel)
        update_simulation_data!(mesh, species, channel)

        simdata(channel).delete_particles && empty!(particles)
    end
end

function send_data!(particles, mesh, channel)
    data = simdata(channel)
    if data.plot_type == :particles
        @batch for i in eachindex(particles.position)
            i > length(data.particle_positions) && break
            data.particle_positions[i] = particles.position[i]
        end
    else
        @batch for i in eachindex(mesh.cells)
            if data.plot_type == :ρ
                data.mesh_values[i] = mesh.cells[i].density
            elseif data.plot_type == :u
                data.mesh_values[i] = norm(mesh.cells[i].bulk_velocity)
            else # data.plot_type == :T
                data.mesh_values[i] = mesh.cells[i].temperature
            end
        end
    end
end

function update_simulation_data!(mesh, species, channel)
    if !any(isnan.(simdata(channel).new_wall))
        add!(mesh, Wall(simdata(channel).new_wall...))
    end

    density = 1.225 * exp(-0.11856 * simdata(channel).inflow_altitude)
    set!(
        mesh.inflow_condition,
        density,
        simdata(channel).inflow_velocity,
        200, # TODO Variable inflow temperature?
        species
    )

    set!(
        mesh.wall_condition,
        simdata(channel).accomodation_coefficient,
        species
    )
end