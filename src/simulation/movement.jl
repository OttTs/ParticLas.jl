function movement_step!(particles, time_step, mesh, thread_id)
    for particle in local(particles, thread_id)
        # 1 Get particle path
        # 2 Get next wall hit
        # 3 Hit wall and goto 1
        # 4 If no wall hit -> Done

    end
end