mutable struct RawMoments
    v⁰::Int64
    v¹::Vec3{Float64}
    v²::Float64
    RawMoments() = new(0, zero(Vec3{Float64}), 0)
end

mutable struct Cell
    raw_moments::Vector{RawMoments}
    relaxation_probability::Float64
    density::Float64
    bulk_velocity::Vec3{Float64}
    temperature::Float64
    scale_parameter::Float64
    tmp_bulk_velocity::Vec3{Float64}
    conservation_ratio::Float64
    walls::Vector{Wall} # TODO We may use an "AllocatedVector"
    function Cell()
        walls = Wall[]
        sizehint!(walls, 1000)
        return new(
            [RawMoments() for _ in 1:Threads.nthreads(:default)],
            0, 0, zero(Vec3{Float64}), 0, 0, zero(Vec3{Float64}), 0, walls
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

cellsize(m::Mesh) = m.length./numcells(m)
cellvolume(m::Mesh) = prod(cellsize(m))
numcells(m::Mesh) = size(m.cells)
inbounds(index, m::Mesh) = checkbounds(Bool, m.cells, index)
inbounds(x::Point2, m::Mesh) = all(0 .< x .< m.length)
index(x, m::Mesh) = CartesianIndex(ceil.(Int, x./ cellsize(m))...)
function boundingindices(l::Line, m::Mesh; startindex=nothing, stopindex=nothing)
    isnothing(startindex) && (startindex = index(pointfrom(l), m))
    isnothing(stopindex) && (stopindex = index(pointto(l), m))
    return (:)(extrema((startindex, stopindex))...)
end

Base.eachindex(m::Matrix, threadid) = (
    @inline(); threadid:Threads.nthreads(:default):length(m)
)

function add!(m::Mesh, w::Wall)
    for index in boundingindices(w.line, m)
        push!(m.cells[index].walls, w)
    end
end

function delete_walls!(m::Mesh, thread_id)
    for i in eachindex(m.cells, thread_id)
        cell = m.cells[i]
        empty!(cell.walls)
    end
end