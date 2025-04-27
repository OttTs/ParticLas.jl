function image(scene, img_path, center_position, height)
    file = GLMakie.load(img_path)
    hsize = (round(Int, GLMakie.size(file)[2]/GLMakie.size(file)[1] * height), height).÷2
    img = GLMakie.image!(scene,
        center_position[1].+(-hsize[1],hsize[1]),
        center_position[2].+(-hsize[2],hsize[2]),
        GLMakie.rotr90(file)
    )
    GLMakie.translate!(img, (0, 0, 1)) # foreground
end

function button(gridpos, label; width=BUTTON_WIDTH)
    return GLMakie.Button(gridpos,
        label=label,
        fontsize=CONTENT_FONTSIZE,
        width=width,
        buttoncolor=BUTTON_COLOR_INACTIVE,
        buttoncolor_active=BUTTON_COLOR_ACTIVE,
        buttoncolor_hover=BUTTON_COLOR_HOVER
    )
end

function close_button(scene, bbox)
    # GLMakie.Rect(pos..., size...) = settings_bbox
    btn_size = 24
    return GLMakie.Button(scene,
        bbox=GLMakie.Rect((bbox.origin+bbox.widths.-btn_size.-10)...,btn_size, btn_size),
        label = "✕",
        height=btn_size,
        width=btn_size,
        cornerradius=btn_size,
        buttoncolor=RGBf(0.2, 0.2, 0.2),
        buttoncolor_hover=RGBf(0.8, 0.2, 0.2),
        buttoncolor_active=RGBf(0.5, 0.2, 0.2),
        labelcolor=RGBf(0.8,0.8,0.8),
        labelcolor_active=RGBf(0.8,0.8,0.8),
        labelcolor_hover=RGBf(0.8,0.8,0.8),
        fontsize=(btn_size*2)÷3,
        strokecolor=MENU_BACKGROUND_COLOR,
        strokewidth=1
    )
end

function toggle(gridpos, label)
    tg = GLMakie.Toggle(gridpos,
        active=true,
        markersize = SLIDER_LINE_WIDTH / 0.66,
        length = SLIDER_LINE_WIDTH * 2.5,
        framecolor_active=SLIDER_COLOR_LEFT,
        framecolor_inactive=SLIDER_COLOR_RIGHT,
        buttoncolor=SLIDER_COLOR_CIRCLE
    )

    grid = GLMakie.hgrid!(
        GLMakie.Label(gridpos, label, fontsize=CONTENT_FONTSIZE),
        tg,
        halign=:left
    )

    return grid, tg
end

function slider(gridpos, range, startvalue, labels)
    sl = GLMakie.Slider(gridpos,
        range=range,
        startvalue=startvalue,
        linewidth = SLIDER_LINE_WIDTH,
        snap=false,
        color_inactive=SLIDER_COLOR_RIGHT,
        color_active_dimmed=SLIDER_COLOR_LEFT,
        color_active=SLIDER_COLOR_CIRCLE
    )

    grid = GLMakie.hgrid!(
        GLMakie.Label(gridpos, labels[1], fontsize=CONTENT_FONTSIZE),
        sl,
        GLMakie.Label(gridpos, labels[2], fontsize=CONTENT_FONTSIZE)
    )

    return grid, sl
end

function slidergrid(gridpos; labels, ranges, startvalues)
    sg = GLMakie.SliderGrid(gridpos,
        ((
            label = labels[i],
            range = ranges[i],
            startvalue = startvalues[i],
            format = "",
            linewidth = SLIDER_LINE_WIDTH,
            snap = false,
            color_inactive = SLIDER_COLOR_RIGHT,
            color_active_dimmed = SLIDER_COLOR_LEFT,
            color_active = SLIDER_COLOR_CIRCLE
        ) for i in eachindex(labels))...
    )

    for i in eachindex(labels)
        sg.labels[i].fontsize[] = CONTENT_FONTSIZE
    end

    return sg
end

function box(scene, position, size, color)
    # Create a box with rounded corners
    strokewidth = (√8 - 2) * SCENE_CORNER_RADIUS
    GLMakie.Box(scene,
        bbox = GLMakie.Rect(position..., size...),
        cornerradius = √2 * SCENE_CORNER_RADIUS,
        width = size[1] + strokewidth,
        height = size[2] + strokewidth,
        strokecolor = BACKGROUND_COLOR,
        strokewidth = strokewidth,
        color = color
    )
end

label(gridpos, label) = GLMakie.Label(gridpos, label; fontsize = SECTION_FONTSIZE, halign=:left)

function menu(gridpos, options, label)
    mn = GLMakie.Menu(
        gridpos,
        dropdown_arrow_size = CONTENT_FONTSIZE * 2 ÷ 3,
        options = options,
        default = options[1],
        fontsize = CONTENT_FONTSIZE,
        cell_color_active=MENU_COLOR_ACTIVE,
        cell_color_hover=MENU_COLOR_HOVER,
        cell_color_inactive_even=MENU_COLOR_EVEN,
        cell_color_inactive_odd=MENU_COLOR_ODD,
        selection_cell_color_inactive=MENU_COLOR_INACTIVE
    )

    grid = GLMakie.hgrid!( # TODO: This will not work since layout[n,:] = ...
        GLMakie.Label(gridpos, label; fontsize = CONTENT_FONTSIZE, halign=:left), mn
    )

    return grid, mn
end