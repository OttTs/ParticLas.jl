include("simulation/constants.jl")
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
    particle_positions::Vector{Point2{Float64}}
    mesh_values::Matrix{Float64}
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
    num_threads
)
    while !data(gui_channel).terminate
        if !data(gui_channel).pause
            insert_particles(particles, inflow, mesh, time_step)
            movement_step!(particles, time_step, mesh, wall_condition)
            deposit!(particles, mesh, thread_id)

            if data(gui_channel).plot_type == :particles
                send!(sim_channel, thread_id) do data
                    index = (thread_id - 1) * length(particles._items)
                    for i in eachindex(particles)
                        index += 1
                        data.particle_positions[index] = particles[i].position # TODO transform to camera system
                    end
                end
            end

            synchronize!(barrier)

            collision_step!(
                mesh,
                time_step,
                species,
                thread_id,
                sim_channel,
                data(gui_channel).plot_type
            )
        end
        !data(gui_channel).delete_walls && delete_walls!(mesh, thread_id)
        synchronize!(barrier)

        if thread_id == 1
            receive!(gui_channel)
       
            # Add wall
            if !isnan.(data(gui_channel).new_wall)
                add!(mesh, data(gui_channel).new_wall)
            end

            set!(
                inflow, 
                data(gui_channel).inflow_altitude, 
                data(gui_channel).inflow_velocity, 
                species, 
                num_threads
            )

            # Set Wall condition
            set!(wall_condition, data(gui_channel).accomodation_coefficient, species)
        end

        synchronize!(barrier)

        !data(gui_channel).delete_particles && clear!(particles)
    end
end

#=
This deposition is not like the one in PICLas.
Here, the particles are added to the list of particles in each cell.
This is done for the collision step, where each cell needs to know its particles.
=#
function deposit!(particles, mesh, thread_id)
    delete_particles!(mesh, thread_id)
    for particle in particles
        index = get_index(particle.position, mesh)
        particles_in_cell = local_list(mesh.cells[index].particles, thread_id)
        push!(particles_in_cell, particle)
    end
end