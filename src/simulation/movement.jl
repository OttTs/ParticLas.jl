function move_particles!(particles, mesh, time_step)
    walls, wall_bc = mesh.walls, mesh.wall_bc[]
    xₚ, vₚ, Iₚ = particles.position, particles.velocity, particles.index

    # TODO This is actually slower with @batch than without: WHY???
    #@batch
    for i in eachindex(vₚ)
        particles.index[i][1] < 0 && continue # Skip deleted particles

        wall = nothing
        Δt = time_step

        for _ in 1:1000 # After 1000 wall hits, just tunnel through it
            trajectory = Line(xₚ[i], Vec2{Float64}(Δt * vₚ[i]))
            Iₙ = index(endpoint(trajectory), mesh) # TODO 1. Is precomputing the index faster? 2. Does mesh introduce allocations?
            wall_hit = find_wall_hit(trajectory, walls; last_wall = wall, I_start = Iₚ[i], I_stop = Iₙ)

            # serial, wall_hit=nothing -> 0.2 frames
            # batch, wall_hit=nothing -> 0.15 frames
            # serial, wall_hit=wall -> 0.32 frames
            #

            if isnothing(wall_hit)
                xₚ[i] = endpoint(trajectory)
                Iₚ[i] = Iₙ
                break
            else
                wall, α = wall_hit
                xₚ[i] += trajectory.vector * α
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

    I_min = CartesianIndex(max.(1, min.(I_start.I, I_stop.I)))
    I_max = CartesianIndex(min.(size(walls)[1:2], max.(I_start.I, I_stop.I)))
    for I in I_min:I_max
        for i in 1:MAX_NUM_WALLS_PER_CELL
            walls[I,i].normal == zero(typeof(walls[I,i].normal)) && break
            walls[I,i] == last_wall && continue

            r = intersect(trajectory, walls[I,i].line)
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
    vₙ = sum(Vec2(velocity) .* wall.normal)

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