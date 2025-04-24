function move_particles!(particles, mesh, time_step)
    walls, wall_bc = mesh.walls, mesh.wall_bc[]
    xₚ, vₚ, Iₚ = particles.position, particles.velocity, particles.index

    @batch for i in eachindex(vₚ)
        wall = nothing
        Δt = time_step

        for _ in 1:1000 # After 1000 wall hits, just tunnel through it
            trajectory = Line(xₚ[i], Vec2{Float64}(Δt * vₚ[i]))
            Iₙ = index(endpoint(trajectory), mesh) # TODO 1. Is precomputing the index faster? 2. Does mesh introduce allocations?
            wall_hit = find_wall_hit(trajectory, walls; last_wall = wall, I_start = Iₚ[i], I_stop = Iₙ)

            if isnothing(wall_hit)
                xₚ[i] = endpoint(trajectory)
                Iₚ[i] = Iₙ
                break
            else
                wall, α = next_hit
                xₚ[i] += vₚ[i] * α * Δt
                vₚ[i] = collide(vₚ[i], wall, wall_bc)
                Iₚ[i] = index(xₚ[i], mesh)
                Δt *= (1 - α)
            end
        end
        inbounds(xₚ[i], mesh) || (Iₚ[i] = CartesianIndex(-1, -1)) # delete particle
    end
end

function find_wall_hit(trajectory::Line, walls; last_wall, I_start, I_stop)
    next_wall = nothing
    fraction = one(Float64)

    I_start = CartesianIndex(min.(max.(I_start.I, 1), size(walls)[1:2]))
    I_stop = CartesianIndex(min.(max.(I_stop.I, 1), size(walls)[1:2]))
    for I in I_start:I_stop
        for i in 1:MAX_NUM_WALLS_PER_CELL
            walls[I,i].normal == zero(type(walls[I,i].normal)) && break
            walls[I,i] == last_wall && continue

            r = intersection(trajectory, walls[I,i].line)
            isnothing(r) && continue
            if r < fraction
                fraction = r
                next_wall = walls[I,i]
            end
        end
    end

    isnothing(next_wall) && return nothing
    return next_wall, fraction
end

function collide(velocity, wall, wall_bc)
    vₙ = sum(velocity .* wall.normal)

    if rand() > wall_bc.accomodation_coefficient
        return typeof(velocity)(
            velocity[1] - 2 * vₙ * wall.normal[1],
            velocity[2] - 2 * vₙ * wall.normal[2],
            velocity[3]
        )
    else
        # Sample v in wall local coordinates and transform back
        # Sign is needed since the particles may hit the wall from both "sides"
        v = sample_inflow_velocity(wall_bc.most_probable_velocity)
        return typeof(velocity)(
            -sign(vₙ) * (wall.normal[1] * v[1] - wall.normal[2] * v[2]),
            -sign(vₙ) * (wall.normal[2] * v[1] + wall.normal[1] * v[2]),
            v[3]
        )
    end
end