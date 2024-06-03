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
    species = Species(3E15, 6.63E-26, 273, 0.77; ref_diameter=4.05E-10)
    time_step = 1E-6
    barrier = Barrier()
    return mesh, species, time_step, barrier
end

function simulation_thread(particles, mesh, species, time_step, barrier, channel, threadid)
    # todo inflow and wall_condition is in mesh
    while !simdata(channel).terminate
        if !simdata(channel).pause
            #------------------------------------------------------------------------------
            # Movement Step
            insert_particles!(particles, mesh, time_step)
            movement_step!(particles, mesh, time_step)
        end
        # We still calculate the relaxation parameters for visualization...
        sum_up_particles!(particles, mesh, threadid)
        synchronize!(barrier)
        #------------------------------------------------------------------------------
        # Collision Step
        relaxation_parameters!(mesh, species, time_step, threadid)
        synchronize!(barrier)
        if !simdata(channel).pause
            relax_particles!(particles, mesh)
            sum_up_particles!(particles, mesh, threadid)
            synchronize!(barrier)
            conservation_parameters!(mesh, threadid)

            synchronize!(barrier)
            conservation_step!(particles, mesh)
            #------------------------------------------------------------------------------
        end

        send_data!(particles, mesh, channel, threadid)

        simdata(channel).delete_walls && delete_walls!(mesh, threadid)
        synchronize!(barrier) # TODO ? synchronize!(barrier)

        if threadid == 1
            swap!(channel) # TODO ? swap_blocking!(channel, 2) TODO It may be faster to just call Threads.@spawn in each loop...
            update_simulation_data!(mesh, species, simdata(channel))
        end

        synchronize!(barrier)
        simdata(channel).delete_particles && empty!(particles)
    end
end

function send_data!(particles, mesh, channel, threadid)
    data = simdata(channel)
    if data.plot_type == :particles
        index = threadid
        for i in eachindex(particles)
            data.particle_positions[index] = particles[i].position
            index += (Threads.nthreads(:default))
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

function update_simulation_data!(mesh, species, channel_data)
    if !any(isnan.(channel_data.new_wall))
        add!(mesh, Wall(channel_data.new_wall...))
    end

    for i in 1:(length(channel_data.object_points)-1)
        start = channel_data.object_points[i]
        stop = channel_data.object_points[i+1]
        add!(mesh, Wall(start, stop))
    end

    density = 1.225 * exp(-0.11856 * channel_data.inflow_altitude)
    set!(
        mesh.inflow_condition,
        density,
        channel_data.inflow_velocity,
        200, # TODO Variable inflow temperature?
        species
    )

    set!(
        mesh.wall_condition,
        channel_data.accomodation_coefficient,
        species
    )
end