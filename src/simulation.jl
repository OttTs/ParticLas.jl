include("simulation/species.jl")
include("simulation/particles.jl")
include("simulation/statistics.jl")
include("simulation/wall.jl")
include("simulation/mesh.jl")
include("simulation/collision_operator.jl")
include("simulation/inflow.jl")
include("simulation/movement.jl")

struct SimulationData
    particles::ThreadedVector{Particle}
    species::Species
    mesh::SimulationMesh
    inflow::InflowCondition
    wall_condition::WallCondition
    time_step::Float64
    thread_barrier::Barrier
end

function setup_simulation()
    num_sim_threads = Threads.nthreads(:default)
    return SimulationData(
        ThreadedVector(Particle, 10^6, num_sim_threads),
        Species(2E16, 6.63E-26, 273, 0.77; ref_diameter=4.05E-10),
        SimulationMesh(MESH_LENGTH, NUM_CELLS, num_sim_threads),
        InflowCondition(),
        WallCondition(),
        1E-6,
        Barrier(num_sim_threads)
    )
end

function simulation_thread(simulation_data, gui_channel, sim_channel, thread_id)
    particles = local_vector(simulation_data.particles, thread_id)
    while !data(gui_channel).terminate
        if !data(gui_channel).pause
            insert_particles(
                particles,
                simulation_data.mesh,
                simulation_data.inflow,
                simulation_data.time_step
            ) # ✓

            movement_step!(
                particles,
                simulation_data.mesh,
                simulation_data.wall_condition,
                simulation_data.time_step
            ) # ✓

            deposit!(particles, simulation_data.mesh, thread_id)

            send_particle_data!(particles, gui_channel, sim_channel, thread_id)

            synchronize!(simulation_data.thread_barrier)

            collision_step!(
                simulation_data.mesh,
                simulation_data.time_step,
                simulation_data.species,
                data(gui_channel).plot_type,
                sim_channel,
                thread_id
            )
        end
        data(gui_channel).delete_walls && delete_walls!(simulation_data.mesh, thread_id)
        synchronize!(simulation_data.thread_barrier)

        if thread_id == 1
            send!(sim_channel)
            receive!(gui_channel)
            update_simulation_data!(simulation_data, gui_channel)
        end

        synchronize!(simulation_data.thread_barrier)
        data(gui_channel).delete_particles && empty!(particles)
    end
end

#=
This deposition is not like the one in PICLas.
Here, the particles are added to the list of particles in each cell.
This is done for the collision step, where each cell needs to know its particles.
=#
function deposit!(particles, mesh, thread_id)
    reset_particles!(mesh, thread_id)
    for particle in particles
        index = get_index(particle.position, mesh)
        particles_in_cell = local_vector(mesh.cells[index].particles, thread_id)
        push!(particles_in_cell, particle)
    end
end

function send_particle_data!(particles, gui_channel, sim_channel, thread_id)
    if data(gui_channel).plot_type == :particles
        set!(sim_channel) do data
            index = 0
            for i in thread_id:Threads.nthreads(:default):length(data.particle_positions)
                index += 1
                index > length(particles) && break
                data.particle_positions[i] = particles[index].position
            end
        end
    end
end

function update_simulation_data!(simulation_data, gui_channel)
    if !any(isnan.(data(gui_channel).new_wall))
        add!(simulation_data.mesh, Wall(data(gui_channel).new_wall...))
    end

    density = 1.225 * exp(-0.11856 * data(gui_channel).inflow_altitude)
    set!(
        simulation_data.inflow,
        density,
        data(gui_channel).inflow_velocity,
        200, # TODO inflow temperature?
        simulation_data.species
    )

    set!(
        simulation_data.wall_condition,
        data(gui_channel).accomodation_coefficient,
        simulation_data.species
    )
end