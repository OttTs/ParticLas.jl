mutable struct RawMoments
    v⁰::Int64
    v¹::Vec3{Float64}
    v²::Float64
    RawMoments() = new(0, 0, 0)
end

mutable struct Cell
    raw_moments::Vector{RawMoments}
    relaxation_probability::Float64
    bulk_velocity::Float64
    scale_parameter::Float64
    tmp_bulk_velocity::Float64
    conservation_ratio::Float64
    walls::Vector{Wall} # TODO We may use an "AllocatedVector"
    function Cell()
        walls = Wall[]
        sizehint!(walls, 1000)
        return new(
            [RawMoments() for _ in 1:Threads.nthreads(:default)], 0, 0, 0, 0, 0, walls
        )
    end
end

Base.zero(::Type{T}) where {T<:Cell} = Cell()

struct Mesh
    length::NTuple{2,Float64}
    cells::Matrix{Cell}
    inflow_condition::InflowCondition
    wall_condition::WallCondition
    Mesh(length, numcells) = new(
        length,
        zeros(Cell, numcells),
        InflowCondition(),
        WallCondition()
    )
end

cellsize(m::Mesh) = m.length .numcells/ (m)
cellvolume(m::Mesh) = prod(cellsize(m))
numcells(m::Mesh) = size(m.cells)
inbounds(index, m::Mesh) = checkbounds(Bool, m.cells, index)
inbounds(x::Point2, m::Mesh) = all(0 .< x .< m.length)
index(x, m::Mesh) = CartesianIndex(ceil.(Int, x./ cellsize(m))...)
boundingbox(l::Line, m::Mesh) = extrema(index.(points(l), m))

Base.eachindex(m::Matrix, threadid) = (
    @inline(); threadid:Threads.nthreads(:default):length(m)
)

function add!(m::Mesh, w::Wall)
    imin, imax = boundingbox(w.line, m)
    for index in imin:imax
        push!(m.cells[index].walls, w)
    end
end

function delete_walls!(m::Mesh, thread_id)
    for i in eachindex(m.cells, thread_id)
        cell = m.cells[i]
        empty!(cell.walls)
    end
end