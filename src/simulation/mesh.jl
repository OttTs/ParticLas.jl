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

