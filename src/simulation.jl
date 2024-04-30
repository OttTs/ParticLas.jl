include("simulation/species.jl")
include("simulation/particles.jl")
include("simulation/statistics.jl")
include("simulation/wall_condition.jl")
include("simulation/mesh.jl")
include("simulation/collision_operator.jl")
include("simulation/inflow.jl")
include("simulation/movement.jl")

const BOLTZMANN_CONST = 1.380649E-23

#=
Used to communicate the particle / mesh data to the GUI thread
=#
struct SimulationData
    particle_positions::Vector{Point2f}
    mesh_values::Matrix{Float32}
    SimulationData(num_cells) = new(
        zeros(Point2f, MAX_NUM_PARTICLES_TO_PLOT),
        zeros(Float32, num_cells)
    )
end

function setup_simulation(mesh_length, num_cells, num_sim_threads)
    return (
        ThreadedVector(Particle, 10^6, num_sim_threads),
        Species(1E21, 6.63E-26, 273, 0.77; ref_diameter=4.05E-10),
        SimulationMesh(mesh_length, num_cells, num_sim_threads),
        InflowCondition(),
        WallCondition(),
        1E-6,
        Barrier(num_sim_threads)
    )
end

function simulation_thread(
    particles,
    species,
    mesh,
    inflow,
    wall_condition,
    time_step,
    barrier,
    gui_channel,
    sim_channel,
    thread_id,
    num_threads,
    position_scaling
)
    set!(inflow, 20, 10000, species, num_threads)
    println(inflow)
    while !data(gui_channel).terminate
        if !data(gui_channel).pause
            @time insert_particles(particles, inflow, mesh, time_step)
            println(length(particles))
            @time movement_step!(particles, time_step, mesh, wall_condition)
            @time deposit!(particles, mesh, thread_id)
            println("---")

            if data(gui_channel).plot_type == :particles
                set!(sim_channel) do data
                    index = 0
                    for i in thread_id:num_threads:length(data.particle_positions)
                        index += 1
                        index > length(particles) && break
                        data.particle_positions[i] = particles[index].position * position_scaling
                    end
                end
            end

            synchronize!(barrier)

            @time collision_step!(
                mesh,
                time_step,
                species,
                thread_id,
                sim_channel,
                data(gui_channel).plot_type
            )
            println("---")
        end
        !data(gui_channel).delete_walls && delete_walls!(mesh, thread_id)
        synchronize!(barrier)

        #if thread_id == 1
        #    send!(sim_channel)
        #    receive!(gui_channel)
#
        #    # Add wall
        #    if !isnan.(data(gui_channel).new_wall)
        #        add!(mesh, data(gui_channel).new_wall)
        #    end
#
        #    # Set Inflow condition
        #    set!(
        #        inflow,
        #        data(gui_channel).inflow_altitude,
        #        data(gui_channel).inflow_velocity,
        #        species,
        #        num_threads
        #    )
#
        #    # Set Wall condition
        #    set!(wall_condition, data(gui_channel).accomodation_coefficient, species)
        #end

        synchronize!(barrier)

        !data(gui_channel).delete_particles && empty!(particles)
    end
end

#=
This deposition is not like the one in PICLas.
Here, the particles are added to the list of particles in each cell.
This is done for the collision step, where each cell needs to know its particles.
=#
function deposit!(particles, mesh, thread_id)
    for particle in particles
        index = get_index(particle.position, mesh)
        particles_in_cell = local_vector(mesh.cells[index].particles, thread_id)
        push!(particles_in_cell, particle)
    end
end