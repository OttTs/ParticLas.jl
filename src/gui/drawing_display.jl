
function setup_display(scene, gui_data; position, size)
    display_scene = Scene(scene,
        viewport=Rect(position..., size...),
        backgroundcolor=DISPLAY_BACKGROUND_COLOR,
        clear=true
    )
    campixel!(display_scene)

    display_particles = Observable(false)
    # 1. Heatmap plot for physical mesh values
    # TODO Define xs, ys and Observable!
    mesh_variable = Observable(Matrix{Float32})
    heatmap!(display_scene, xs, ys, mesh_variable;
        interpolate = true,
        colormap = :afmhot,
        visible =  @lift(!$display_particles)
    )

    # 2. Scatter plot for particles
    particle_points = Observable(Point2f[])
    scatter!(display_scene, particle_points;
        marker = GLMakie.FastPixel(),
        markersize = 2,
        color = :black, # TODO color with velocity?
        visible = display_particles
    )

    # 3. Lines for walls
    # TODO Replace List with standard array + sizehint!
    wall_points = Observable(Point2f[])
    sizehint!(wall_points[], 10^5)
    lines!(display_scene, wall_points;
        linewidth = 2,
        color = :blue
    )

    # 4. Create rounded edges
    stroke_width = (√8 - 2) * SCENE_CORNER_RADIUS
    Box(display_scene,
        bbox=Rect(0, 0, size...),
        cornerradius=√2 * SCENE_CORNER_RADIUS,
        width=size[1] + stroke_width,
        height=size[2] + stroke_width,
        strokewidth=stroke_width,
        strokecolor=DISPLAY_BACKGROUND_COLOR,
        color=:transparent
    )

    # Handle drawing
    drawing = Ref{Bool}(false)
    on(events(display_scene).mouseposition) do position
        pressed = ispressed(window, Mouse.left)
        inside = isinside(position, size)

        if pressed && inside && drawing[]
            continuedrawing(wall_points, position, size, gui_data)
        elseif pressed && inside && !drawing[]
            drawing[] = true
            startdrawing(wall_points, position)
        elseif drawing[]
            drawing[] = false
            stopdrawing(gui, size[2], gui_data)
        end
    end

    # Return all Observables created for the display:
    return mesh_variable, particle_points, display_particles, wall_points
end

function isinside(position, resolution)
    return all(0 .< position .< resolution) # TODO 0 or offset?
end

function continuedrawing(wall_points, position, scaling, gui_data)
    wall_points[][end] = position
    if norm(wall_points[][end] - wall_points[][end-1]) > 5
        gui_data.new_wall = (wall_points[][end-1], wall_points[][end]) ./ scaling
        push!(wall_points[], position)
    end
    notify(wall_points)
end

function startdrawing(wall_points, position)
    push!(wall_points[], position)
    push!(wall_points[], position)
    notify(wall_points)
end

function stopdrawing(wall_points, scaling, gui_data)
    gui_data.new_wall = (wall_points[][end-1], wall_points[][end]) ./ scaling
    push!(wall_points[], Point2f(NaN))               
    notify(wall_points)
end