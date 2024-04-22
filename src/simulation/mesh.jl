#struct Cell
#    particles::Vector{Particle}
#    num_particles::Int64
#
#    walls::Vector{Wall}
#    num_walls::Int64
#end
#
#struct Mesh
#    length::NTuple{2,Int64}
#    cells::Matrix{Cell}
#
#    function Mesh(length)
#        new(length, zeros(Cell, num_cells))
#    end
#end
#
#cellsize(m::Mesh) = m.length./num_cells(m)
#
#num_cells(m::Mesh) = size(m.length)

#=
Definition of a cell iterator for a convenient loop over all thread local cells.
With this, we can loop over the cells by calling:

for i in cell_indices(num_cells(mesh), num_threads, thread_id)
    cell = mesh.cells[i]
    ...
end
=#
struct CellIterator
    _num_cells::NTuple{2,Int64}
    _num_threads::Int64
    _shift::Int64
    _offset::Int64

    function CellIterator(num_cells, num_threads, thread_id)
        shift = max(1, floor(Int64, num_threads/2))
        return new(num_cells, num_threads, shift, thread_id)
    end
end

cell_indices(num_cells, num_threads, thread_id) = CellIterator(num_cells, num_threads, thread_id)

function Base.iterate(iter::CellIterator)
    # Assuming that the number of cells in x direction is lower than the number of threads!
    return (CartesianIndex(iter._offset, 1), CartesianIndex(iter._offset, 1))
end

function Base.iterate(iter::CellIterator, state)
    next = state + CartesianIndex(iter._num_threads, 0)
    if next[1] > iter._num_cells[1]
        if next[2] >= iter._num_cells[2]
            return nothing
        end

        next = CartesianIndex(
            (iter._offset + iter._shift * next[2] - 1) % iter._num_threads + 1,
            next[2] + 1
        )
    end
    return (next, next)
end



#=
density, velocity, temperature, collision_probability, (most_probable_velocity, ratio, new_velocity)

Variables needed for displaying
- density
- temperature
- velocity_magnitude

Variables needed for particle collisions
- collision_probability
- most_probable_velocity NO scale! scale is used
- bulk_velocity

Variables needed for conservation:
- ratio
- new_bulk_velocity
- bulk_velocity
=#

#=
Walls:
- Storage on the mesh
- Each cell stores the walls!


=#

struct Moments
    num_particles::Matrix{Int64}
    mean_velocity::Matrix{Float64}
    variance::Matrix{Float64}
end