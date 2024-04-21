# TODO Do Everything per cell and then moments is actually Matrix{Moments}
struct SummedUpVariables
    num_particles::Matrix{Int64}
    velocity::Matrix{Point3{Float64}}
    velocity_squared::Matrix{Float64}
    SummedUpVariables(mesh) = new{
        zeros(Int64, mesh.num_cells),
        zeros(Point3{Float64}, mesh.num_cells),
        zeros(Float64, mesh.num_cells)
    }
end

function reset!(v::SummedUpVariables)
    v.num_particles .= 0
    v.velocity .= zero(Point3{Float64})
    v.velocity_squared .= 0
end

struct Moments
    num_particles::Matrix{Int64}
    bulk_velocity::Matrix{Point3{Float64}}
    velocity_variance::Matrix{Float64}
    _summed_up_variables::Vector{SummedUpVariables}
    _rows_per_thread::Vector{UnitRange{Int64}}
    function Moments(num_threads, mesh)
        # Split the rows into parts of (approximately) equal size
        _rows_per_thread = UnitRange{Int64}[]
        num_done = 0
        for i in num_threads:-1:1
            r = round(Int64, (mesh.num_cells[1] - num_done) / i)
            push!(_rows_per_thread, (num_done+1):(num_done+r))
            num_done += r
        end
        return new{num_threads}(
            zeros(Int64, mesh.num_cells),
            zeros(Point3{Float64}, mesh.num_cells),
            zeros(Float64, mesh.num_cells),
            collect(SummedUpVariables(mesh) for _ in 1:num_threads),
            _rows_per_thread
        )
    end
end

function reset!(m::Moments, thread_id)
    reset!(m._summed_up_variables[thread_id])
end

function sum_up_particles!(m::Moments, particles, thread_id)
    reset!(m, thread_id)

    summed_up = m._summed_up_variables[thread_id]
    for p in particles
        idx = p.index
        vel = p.velocity
        summed_up.num_particles[idx] += 1
        summed_up.velocity[idx] += vel
        summed_up.velocity_squared[idx] += sum(vel ⋅ vel)
    end
end

function calculate_moments!(m::Moments, thread_id)
    num_threads = length(_summed_up_variables)
    num_columns = size(m.num_particles)[2]

    for r in m._rows_per_thread[thread_id], c in 1:num_columns
        N = sum( _summed_up_variables[i].num_particles[r,c] for i in 1:num_threads)
        ∑v¹ = sum(_summed_up_variables[i].velocity[r,c] for i in 1:num_threads)
        ∑v² = sum(_summed_up_variables[i].velocity_squared[r,c] for i in 1:num_threads)

        m.num_particles[r,c] = N 

        if N > 0
            m.bulk_velocity[r,c] = ∑v¹ / N
            ∑c² = ∑v² - sum(∑v¹ ⋅ ∑v¹) / N
        else
            m.bulk_velocity[r,c] = 0
            ∑c² = 0
        end

        if N > 1
            m.velocity_variance[r,c] = ∑c² / (3 * (N - 1))
        else
            m.velocity_variance[r,c] = 0
        end   
    end
end
