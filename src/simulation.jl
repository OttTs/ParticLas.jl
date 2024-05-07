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
    barrier = Barrier()
    return mesh, species, time_step, barrier
end

function simulation_thread(particles, mesh, species, time_step, barrier, channel, threadid)
    # todo inflow and wall_condition is in mesh
    while !simdata(channel).terminate
        if !simdata(channel).pause
            if threadid == 1
                timing = simdata(channel).timing_data
                timing.sim_start = frametime()
            end

            #------------------------------------------------------------------------------
            # Movement Step
            insert_particles!(particles, mesh, time_step)
            threadid == 1 && (timing.pure_insertion = frametime())
            movement_step!(particles, mesh, time_step)
            threadid == 1 && (timing.pure_movement = frametime())
            sum_up_particles!(particles, mesh, threadid)
            threadid == 1 && (timing.sync = frametime())
            synchronize_blocking!(barrier, threadid)
            threadid == 1 && (timing.movement = frametime())
            #------------------------------------------------------------------------------
            # Collision Step
            relaxation_parameters!(mesh, species, time_step, threadid)
            synchronize_blocking!(barrier, threadid)
            threadid == 1 && (timing.relax_parameters = frametime())
            relax_particles!(particles, mesh)
            sum_up_particles!(particles, mesh, threadid)
            synchronize_blocking!(barrier, threadid)
            threadid == 1 && (timing.relax = frametime())
            conservation_parameters!(mesh, threadid)

            synchronize_blocking!(barrier, threadid)
            threadid == 1 && (timing.conservation_parameters = frametime())
            conservation_step!(particles, mesh)
            threadid == 1 && (timing.conservation = frametime())
            #------------------------------------------------------------------------------
        end

        send_data!(particles, mesh, channel, threadid)

        simdata(channel).delete_walls && delete_walls!(mesh, threadid)
        synchronize!(barrier)

        if threadid == 1
            swap!(channel)
            update_simulation_data!(mesh, species, channel)
        end

        synchronize!(barrier)
        simdata(channel).delete_particles && empty!(particles)
    end
end

function send_data!(particles, mesh, channel, threadid)
    data = simdata(channel)
    if data.plot_type == :particles
        step = floor(Int, Threads.nthreads(:default) * maxlength(particles) /
            length(data.particle_positions))
        index = threadid
        for i in 1:step:length(particles)
            data.particle_positions[index] = particles[i].position
            index += Threads.nthreads(:default)
        end
    else
        for i in eachindex(mesh.cells, threadid)
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