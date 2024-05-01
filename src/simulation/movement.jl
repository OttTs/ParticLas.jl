function movement_step!(particles, mesh, wall_condition, time_step)
    for index in eachindex(particles)
        particle = particles[index]

        wall = nothing
        Δt = time_step
        while true
            trajectory = Line(particle.position, Vec2{Float64}(Δt * particle.velocity))
            wall, fraction = next_wall_hit(trajectory, mesh; last_wall=wall)
            particle.position += trajectory.vector * fraction

            if isnothing(wall)
                break
            else
                Δt *= (1 - fraction)
                collide!(particle, wall, wall_condition)
            end
        end
        inbounds(particle.position, mesh) || deleteat!(particles, index)
    end
end

function next_wall_hit(trajectory::Line, mesh::SimulationMesh; last_wall=nothing)
    index_start = get_index(pointfrom(trajectory), mesh)
    index_stop = get_index(pointto(trajectory), mesh)

    next_wall = nothing 
    fraction = one(Float64)

    # Check all cells in the "bounding rectangle"
    for index in index_start:index_stop
        inbounds(index, mesh) || continue
        cell = mesh.cells[index]

        for wall in cell.walls
            wall == last_wall && continue
            r = intersect(trajectory, wall.line)
            isnothing(r) && continue
            if r < fraction
                fraction = r
                next_wall = wall
            end
        end
    end

    return next_wall, fraction
end

function collide!(particle, wall, wall_condition)
    normal_velocity = particle.velocity ⋅ wall.normal

    if rand() > wall_condition.accomodation_coefficient
        particle.velocity -= 2 * normal_velocity * wall.normal
    else
        # Sample v in wall local coordinates and transform back
        # Sign is needed since the particles may hit the wall from both "sides"
        v = sample_inflow_velocity(wall_condition.most_probable_velocity)
        transform_matrix = @SMatrix [ wall.normal[1]    -wall.normal[2] 0 ;
                                      wall.normal[2]     wall.normal[1] 0 ;
                                                   0                  0 1 ]
        v = transform_matrix * (v .* (sign(normal_velocity), 1, 1))
    end
end