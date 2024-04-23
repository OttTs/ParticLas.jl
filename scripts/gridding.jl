using GLMakie

function main()
    nx = rand(1:50)
    ny = rand(1:50)

    num_threads = rand(4:8)

    shift = max(1, floor(Int64, num_threads/2))
    #while num_threads % shift == 0 && shift > 1
    #    shift -= 1
    #end

    println(shift)

    fig = Figure()
    Axis(fig[1,1])

    for i in 1:num_threads
        col = RGBf(rand(3)...)

        offset = i
        for iy in 1:ny
            for ix in offset:num_threads:nx
                poly!(Point2f[(ix, iy), (ix+1, iy), (ix+1, iy+1), (ix, iy+1)], color = col)
                #Box(fig[iy, ix], color = col)
            end
            offset += shift
            if offset > num_threads
                offset -= num_threads
            end
        end
    end

    fig
end
main()