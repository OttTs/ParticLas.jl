function setup_drawing_listener(scene, gui, walls)
    isdrawing = Ref{Bool}(false)

    GLMakie.on(GLMakie.events(scene).mouseposition) do p
        p = p .- BORDER_WIDTH # TODO Why - BORDER_WIDTH?

        ispressed = GLMakie.ispressed(scene, GLMakie.Mouse.left)
        isinside = all(0 .< p .< size)

        if ispressed && isinside && !isdrawing[]
            isdrawing[] = true
            push!(walls[], p, p)
        elseif ispressed && isinside && isdrawing[]
            walls[][end] = p
            if norm(walls[][end] - walls[][end-1]) > MIN_WALL_LENGTH
                push!(gui.new_walls, ((walls[][end-1], walls[][end]), size)) # TODO
                push!(walls[], p)
            end
        elseif isdrawing[]
            isdrawing[] = false
            push!(gui.new_walls, ((walls[][end-1], walls[][end]), size)) # TODO
            push!(walls[], Point2f(NaN))
        end

        notify(walls)
    end
end