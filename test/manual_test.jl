using ParticLas

particles = ParticLas.ThreadedVector(ParticLas.Particle, 1)
particles = ParticLas.local_list(particles, 1)
species = ParticLas.Species(1E17, 6.63E-26, 273, 0.77; ref_diameter=4.05E-10)
inflow =ParticLas.InflowCondition(0, 0, 0)
ParticLas.set!(inflow, 1.225, 100, 273, species, 1)
mesh = ParticLas.SimMesh((2, 1), (120, 60), 1, 1000, 1000)
time_step = 1E-6

bc = ParticLas.WallCondition(1, 0)

ParticLas.insert_particles(particles, inflow, mesh, time_step)
ParticLas.movement_step!(particles, time_step, mesh, bc)
ParticLas.deposit!(particles, mesh, 1)
ParticLas.collision_step!(mesh, time_step, species, 1)