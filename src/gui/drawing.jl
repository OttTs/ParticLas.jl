function setup_drawing_listener(scene, gui, walls)
    isdrawing = Ref{Bool}(false)

    GLMakie.on(GLMakie.events(scene).mouseposition) do p
        p = p .- BORDER_WIDTH

        ispressed = GLMakie.ispressed(scene, GLMakie.Mouse.left)
        isinside = all(0 .< p .< size(scene))

        if ispressed && isinside && !isdrawing[]
            isdrawing[] = true
            push!(walls[], p, p)
        elseif ispressed && isinside && isdrawing[]
            walls[][end] = p
            if norm(walls[][end] - walls[][end-1]) > MIN_WALL_LENGTH
                push!(gui.new_walls, (walls[][end-1]./gui.display_scaling, walls[][end]./gui.display_scaling))
                push!(walls[], p)
            end
        elseif isdrawing[] && ispressed && !isinside
            isdrawing[] = false
            walls[][end] = p
            push!(gui.new_walls, (walls[][end-1]./gui.display_scaling, walls[][end]./gui.display_scaling))
            push!(walls[], Point2f(NaN))
        end

        notify(walls)
    end

    GLMakie.on(GLMakie.events(scene).mousebutton) do _
        p = GLMakie.events(scene).mouseposition[] .- BORDER_WIDTH

        ispressed = GLMakie.ispressed(scene, GLMakie.Mouse.left)

        if !ispressed && isdrawing[]
            isdrawing[] = false
            walls[][end] = p
            push!(gui.new_walls, (walls[][end-1]./gui.display_scaling, walls[][end]./gui.display_scaling))
            push!(walls[], Point2f(NaN))
        end
    end
end