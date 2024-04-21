# Channels...
# 
#=
From the interactive thread, the workers need:
- pause / reset (particles, walls) / terminate
- walls
- Inflow condition (velocity, density)
- Wall accomodation_coefficient
- do collisions

From the workers, the interactive thread needs
- Particle positions
or
- density / velocity / temperature

What is always the same?

=#

struct SettingsData
    terminate::Bool
    pause::Bool
    delete_particles::Bool
    delete_walls::Bool

    do_particle_collisions::Bool
    
    drawn_wall::NTuple{2, Point2{Float64}}
    accomodation_coefficient::Float64

    inflow_density::Float64
    inflow_velocity::Float64

    draw_type::Symbol # :particles, :density, :velocity, :temperature
end