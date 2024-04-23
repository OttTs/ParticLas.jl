struct Wall
    normal::Vec2{Float64} # TODO Change many Point3 to Vec3!
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
        ThreadedList(Particle(), max_num_particles, num_threads),
        List(Wall(), max_num_walls)
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

@inline function get_index(x, m::Mesh)
    return CartesianIndex(begin
            r = x[i]
            index = 0
            while r > 0
                index += 1
                r -= Δ
            end
            return index
        end for i in 1:2)
end
