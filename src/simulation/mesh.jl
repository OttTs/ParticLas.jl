struct Mesh
    num_cells::NTuple{2,Int64}
    length::NTuple{2,Int64}
end

cellsize(m::Mesh) = m.length./m.num_cells

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