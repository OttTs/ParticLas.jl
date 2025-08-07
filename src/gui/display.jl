
#=
Display

For the display, a Box is drawn and a scene is created.
This scene is used to draw the particles, walls and heatmap.

Data for the simulation is directly updated in the channel.
=#
function draw_display(scene, variable_to_plot, color_range, walls, channel; position, size)
    display_scene = GLMakie.Scene(scene;
        viewport=GLMakie.Rect(position..., size...),
        backgroundcolor=DISPLAY_BACKGROUND_COLOR,
        clear=true,
        camera = GLMakie.campixel!
    )

    # Create a heatmap for plotting the macroscopic values
    mesh_values = Observable(zeros(Float32, NUM_CELLS))
    GLMakie.image!(display_scene,
        (0,size[1]),
        (0,size[2]),
        mesh_values;
        interpolate = true,
        colormap = :afmhot,
        colorrange = color_range,
        visible = GLMakie.@lift($(variable_to_plot) != :particles)
    )

    # Create a scatter plot for the particles
    particle_points = Observable{Vector{Point2f}}(zeros(Point2f, NUM_PARTICLES_VISU))
    GLMakie.scatter!(display_scene, particle_points;
        #marker = GLMakie.FastPixel(),
        markersize = 4,
        color = :black,
        visible = GLMakie.@lift($(variable_to_plot) == :particles)
    )

    # Create a lines plot for the walls
    GLMakie.lines!(display_scene, walls; linewidth = 2, color = BLUE_DARK)

    # Create a box around the display area to get rounded corners
    box(display_scene, (0, 0), size, :transparent)

    scaling = GLMakie.viewport(display_scene)[].widths ./ MESH_LENGTH
    setup_drawing_listener(display_scene, walls, channel, scaling)

    GLMakie.on(GLMakie.events(scene).tick) do _
        if variable_to_plot[] == :particles
            xₚ = data(channel,1).particle_positions
            for i in eachindex(xₚ)
                xₚ[i] = xₚ[i] .* scaling
            end
            particle_points[] = xₚ
        else
            mesh_values[] = data(channel,1).mesh_values
        end
    end

    return scaling, particle_points, mesh_values
end


function setup_drawing_listener(scene, walls, channel, scaling)
    isdrawing = Ref{Bool}(false)

    GLMakie.on(GLMakie.events(scene).mouseposition) do p
        p = p .- GLMakie.viewport(scene)[].origin
        ispressed = GLMakie.ispressed(scene, GLMakie.Mouse.left)
        isinside = all(0 .< p .< size(scene))

        if ispressed && isinside && !isdrawing[]
            isdrawing[] = true
            push!(walls[], p, p)
        elseif ispressed && isinside && isdrawing[]
            walls[][end] = p
            if norm(walls[][end] - walls[][end-1]) > MIN_WALL_LENGTH
                add_new_wall!(data(channel, 1).new_walls, walls, scaling)
                push!(walls[], p)
            end
        elseif isdrawing[] && ispressed && !isinside
            isdrawing[] = false
            walls[][end] = p
            add_new_wall!(data(channel, 1).new_walls, walls, scaling)
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
            add_new_wall!(data(channel, 1).new_walls, walls, scaling)
            push!(walls[], Point2f(NaN))
        end
    end
end

function add_new_wall!(new_walls, walls, scaling)
    push!(new_walls, (walls[][end-1]./scaling, walls[][end]./scaling))
end