struct Wall
    normal::Vec2{Float64}
    line::Line
    function Wall(a, b)
        v = Vec(b .- a)
        normal = Vec(-v[2], v[1]) / norm(v)
        return new(normal, Line(Point2{Float64}(a), v))
    end
end

struct Cell
    particles::ThreadedVector{Particle}
    walls::Vector{Wall}
    function Cell(num_threads)
        walls = Wall[]
        sizehint!(walls, 10000)
        return new(ThreadedVector(Particle, num_threads), walls)
    end
end

struct Mesh
    length::NTuple{2,Int64}
    cells::ThreadedMatrix{Cell}
    function Mesh(length, num_cells, num_threads)
        cells = ThreadedMatrix(Cell(num_threads), num_cells, num_threads)
        return new(length, cells)
    end
end

cellsize(m::Mesh) = m.length./num_cells(m)

cellvolume(m::Mesh) = prod(cellsize(m))

num_cells(m::Mesh) = size(m.cells)

inbounds(index, m::Mesh) = checkbounds(Bool, m.cells._items, index)

inbounds(x::Point2, m::Mesh) = all(0 .< x .< m.length)

@inline get_index(x, m::Mesh) = CartesianIndex((
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

function add!(m::Mesh, w::Wall)
    min_index,max_index = minmax(
        get_index(pointfrom(w.line), m),
        get_index(pointto(w.line), m)
    )
    for index in min_index:max_index
        push!(w.cells[index].walls, w)
    end
end

function delete_particles!(m::Mesh, thread_id)
    # Attention! Deletes the Lists for all threads! Only call in collision step!
    for cell in local_items(m.cells, thread_id)
        clear!(cell.particles)
    end
end

function delete_walls!(m::Mesh, thread_id)
    for cell in local_items(m.cells, thread_id)
        clear!(cell.walls)
    end
end