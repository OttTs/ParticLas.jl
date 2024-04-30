struct Wall
    normal::Vec2{Float64}
    line::Line
    function Wall(a, b)
        v = Vec(b .- a)
        normal = Vec(-v[2], v[1]) / norm(v)
        return new(normal, Line(Point2{Float64}(a), v))
    end
end

Base.zero(::Type{T}) where {T<:Wall} = Wall(zero(Point2f), zero(Point2f))

struct Cell
    particles::ThreadedVector{Particle}
    walls::AllocatedVector{Wall}
    function Cell(num_threads)
        max_num_items = 10^3
        walls = AllocatedVector(Wall, max_num_items)
        return new(ThreadedVector(Particle, max_num_items, num_threads), walls)
    end
end

Base.zero(::Type{T}, num_threads) where {T<:Cell} = Cell(num_threads)

struct SimMesh
    length::NTuple{2,Float64}
    cells::ThreadedMatrix{Cell}
    function SimMesh(length, num_cells, num_threads)
        cells = ThreadedMatrix(Cell, num_cells, num_threads; args=num_threads)
        return new(length, cells)
    end
end

cellsize(m::SimMesh) = m.length./num_cells(m)

cellvolume(m::SimMesh) = prod(cellsize(m))

num_cells(m::SimMesh) = size(m.cells)

inbounds(index, m::SimMesh) = checkbounds(Bool, m.cells._items, index)

inbounds(x::Point2, m::SimMesh) = all(0 .< x .< m.length)

@inline get_index(x, m::SimMesh) = CartesianIndex((
    begin
        r = x[i]
        index = 0
        while r > 0
            index += 1
            r -= cellsize(m)[1]
        end
        index
    end for i in 1:2
)...)

function add!(m::SimMesh, w::Wall)
    min_index,max_index = minmax(
        get_index(pointfrom(w.line), m),
        get_index(pointto(w.line), m)
    )
    for index in min_index:max_index
        push!(w.cells[index].walls, w)
    end
end

function delete_particles!(m::SimMesh, thread_id)
    # Attention! Deletes the Lists for all threads! Only call in collision step!
    for i in local_indices(m.cells, thread_id)
        cell = m.cells[i]
        empty!(cell.particles)
    end
end

function delete_walls!(m::SimMesh, thread_id)
    for i in local_indices(m.cells, thread_id)
        cell = m.cells[i]
        empty!(cell.walls)
    end
end