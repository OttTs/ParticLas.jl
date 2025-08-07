#=
Renderloop Functions

Custom renderloop functions, mostly copied from GLMakie
Makie FPS renderloop sleeps, which is inaccurate, thus we use a busy wait
=#
function renderloop(screen)
    GLMakie.isopen(screen) || error("Screen most be open to run renderloop!")
    # Context needs to be current for GLFW.SwapInterval
    GLMakie.gl_switch_context!(screen.glscreen)
    try
        if screen.config.vsync
            GLMakie.GLFW.SwapInterval(1)
            vsynced_renderloop(screen)
        else
            GLMakie.GLFW.SwapInterval(0)
            fps_renderloop(screen)
        end
    catch e
        @warn "error in renderloop" exception = (e, Base.catch_backtrace())
        rethrow(e)
    end
    if screen.close_after_renderloop
        try
            @debug("Closing screen after quitting renderloop!")
            GLMakie.close(screen)
        catch e
            @warn "error closing screen" exception = (e, Base.catch_backtrace())
        end
    end
    screen.rendertask = nothing
    return
end

function vsynced_renderloop(screen)
    while GLMakie.isopen(screen) && !screen.stop_renderloop[]
        GLMakie.pollevents(screen, GLMakie.Makie.RegularRenderTick) # GLFW poll
        GLMakie.poll_updates(screen)
        GLMakie.render_frame(screen)
        yield()
        GC.safepoint()
        GLFW.SwapBuffers(GLMakie.to_native(screen))
    end
    return
end

function fps_renderloop(screen)
    while GLMakie.isopen(screen) && !screen.stop_renderloop[]
        starttime = frametime(screen.config.framerate)

        GLMakie.pollevents(screen, GLMakie.Makie.RegularRenderTick)
        GLMakie.poll_updates(screen)
        GLMakie.render_frame(screen)
        yield()
        GLFW.SwapBuffers(GLMakie.to_native(screen))

        GC.safepoint()

        # Busy wait until the next frame
        while frametime(screen.config.framerate) - starttime < 1; end
    end
    return
end

#function renderloop(gui, channel)
#    while !gui.terminate[]
#        starttime = frametime()
#
#        reset!(gui)
#
#        # Get new events and render new frame
#        #@sync begin
#            GLMakie.pollevents(gui.screen, GLMakie.Makie.RegularRenderTick) # TODO ...
#            GLMakie.render_frame(gui.screen)
#            GLFW.SwapBuffers(gui.screen.glscreen)
#        #end
#
#        # Send and receive the data
#        send!(gui, data(channel, 1))
#        t1 = frametime()
#        swap!(channel, 1)
#        t2 = frametime()
#        update!(gui, data(channel, 1))
#        #yield() # We need to yield to allow other tasks to run! (DO WE?)
#
#        # TODO Delete (Only debug)
#        open("gui.time", "w") do io
#            write(io, "$(round(frametime() - t2 + t1 - starttime; digits=2))")
#        end
#
#        # Wait for the rest of the frame
#        #while frametime() - starttime < 1; end
#    end
#end