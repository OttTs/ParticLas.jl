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

struct SimulationMesh
    length::NTuple{2,Float64}
    cells::ThreadedMatrix{Cell}
    function SimulationMesh(length, num_cells, num_threads)
        cells = ThreadedMatrix(Cell, num_cells, num_threads; args=num_threads)
        return new(length, cells)
    end
end

cellsize(m::SimulationMesh) = m.length./num_cells(m)

cellvolume(m::SimulationMesh) = prod(cellsize(m))

num_cells(m::SimulationMesh) = size(m.cells)

inbounds(index, m::SimulationMesh) = checkbounds(Bool, m.cells._items, index)

inbounds(x::Point2, m::SimulationMesh) = all(0 .< x .< m.length)

@inline get_index(x, m::SimulationMesh) = CartesianIndex(ceil.(Int, x ./ cellsize(m))...)
#@inline get_index(x, m::SimulationMesh) = CartesianIndex((
#    begin
#        r = x[i]
#        index = 0
#        while r > 0
#            index += 1
#            r -= cellsize(m)[i]
#        end
#        index
#    end for i in 1:2
#)...)


function add!(m::SimulationMesh, w::Wall)
    min_index,max_index = extrema((
        get_index(pointfrom(w.line), m),
        get_index(pointto(w.line), m)
    ))
    for index in min_index:max_index
        push!(m.cells[index].walls, w)
    end
end

function reset_particles!(m::SimulationMesh, thread_id)
    # Needed before depo!
    for cell in m.cells
        local_particles = local_vector(cell.particles, thread_id)
        empty!(local_particles)
    end
end

function delete_walls!(m::SimulationMesh, thread_id)
    for i in local_indices(m.cells, thread_id)
        cell = m.cells[i]
        empty!(cell.walls)
    end
end