struct Wall
    normal::Vec2{Float64}
    line::Line
    function Wall(a, b)
        v = Vec(b - a)
        normal = Vec(-v[2], v[1]) / norm(v)
        return new(normal, Line(a, v))
    end
end

struct Cell
    particles::ThreadedList{Particle}
    walls::List{Wall}
    Cell(max_num_particles, num_threads, max_num_walls) = new(
        ThreadedList(Particle, max_num_particles, num_threads),
        List(Wall, max_num_walls)
    )
end

struct Mesh
    length::NTuple{2,Int64}
    cells::ThreadedMatrix{Cell}
    function Mesh(length, num_cells, num_threads, max_num_particles, max_num_walls)
        cells = ThreadedMatrix(
            Cell(max_num_particles, num_threads, max_num_walls), 
            num_cells, 
            num_threads
        )
        return new(length, cells)
    end
end

cellsize(m::Mesh) = m.length./num_cells(m)

cellvolume(m::Mesh) = prod(cellsize(m))

num_cells(m::Mesh) = size(m.cells)

@inline get_index(x, m::Mesh) = CartesianIndex(
    begin
        r = x[i]
        index = 0
        while r > 0
            index += 1
            r -= cellsize(m)[1]
        end
        index
    end for i in 1:2
)

function add!(m::Mesh, w::Wall)
    for index in get_index(pointfrom(w.line), m):get_index(pointto(w.line), m)
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