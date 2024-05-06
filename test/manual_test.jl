using ParticLas

@time particles = ParticLas.AllocatedVector(particles, 10)
@time species = ParticLas.Species(1E17, 6.63E-26, 273, 0.77; ref_diameter=4.05E-10)
@time inflow =ParticLas.InflowCondition()
@time ParticLas.set!(inflow, 1.225, 100, 273, species, 1)
@time mesh = ParticLas.Mesh((2, 1), (120, 60), 1)
@time time_step = 1E-6
@time bc = ParticLas.WallCondition(1, 0)
@time ParticLas.insert_particles!(particles, inflow, mesh, time_step)
@time ParticLas.movement_step!(particles, time_step, mesh, bc)
@time ParticLas.deposit!(particles, mesh, 1)
@time ParticLas.collision_step!(mesh, time_step, species, 1)