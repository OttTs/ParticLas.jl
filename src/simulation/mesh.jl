struct Mesh
    length::NTuple{2,Float64}

    inflow_bc::Ref{InflowBC}
    wall_bc::Ref{WallBC}

    walls::Array{Wall,3}

    ∑v⁰::Array{Int64,3}
    ∑v¹::Array{Vec3{Float64},3}
    ∑v²::Array{Float64,3}

    density::Array{Float64,2}
    velocity::Array{Vec3{Float64},2}
    temperature::Array{Float64,2}
    relaxation_probability::Array{Float64,2}

    unconserved_velocity::Array{Vec3{Float64},2}
    scale_parameter::Array{Float64,2}
    conservation_ratio::Array{Float64,2}

    Mesh(length) = new(
        length,

        Ref{InflowBC}(),
        Ref{WallBC}(),

        Array{Wall,3}(undef, NUM_CELLS..., MAX_NUM_WALLS_PER_CELL),

        Array{Int64,3}(undef, NUM_CELLS..., Threads.nthreads(:default)),
        Array{Vec3{Float64},3}(undef, NUM_CELLS..., Threads.nthreads(:default)),
        Array{Float64,3}(undef, NUM_CELLS..., Threads.nthreads(:default)),

        Array{Float64,2}(undef, NUM_CELLS),
        Array{Vec3{Float64},2}(undef, NUM_CELLS),
        Array{Float64,2}(undef, NUM_CELLS),
        Array{Float64,2}(undef, NUM_CELLS),

        Array{Vec3{Float64},2}(undef, NUM_CELLS),
        Array{Float64,2}(undef, NUM_CELLS),
        Array{Float64,2}(undef, NUM_CELLS)
    )
end

cellsize(m::Mesh) = m.length ./ NUM_CELLS
inbounds(x::Point2, m::Mesh) = all(0 .< x .< m.length)
index(x, m::Mesh) = CartesianIndex(ceil.(Int, x ./ cellsize(m))...)

function add!(m::Mesh, w::Wall)
    walls = m.walls

    cell_indices = range(extrema((index(startpoint(w.line), m), index(endpoint(w.line), m)))...)
    # TODO @batch is probably slower here
    @batch for I in cell_indices
        for i in 1:MAX_NUM_WALLS_PER_CELL
            walls[I,i].normal == zero(typeof(walls[I,i].normal)) || continue

            walls[I,i] = w
            if i < MAX_NUM_WALLS_PER_CELL
                walls[I,i+1] = Wall()
            end

            break
        end
    end
end

function delete_walls!(m::Mesh)
    walls = m.walls
    cell_indices = CartesianIndices(NUM_CELLS)
    @batch for I in cell_indices
        walls[I,1] = Wall()
    end
end