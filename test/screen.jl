# This is a test for a simple screen using GLMakie

using GLMakie
using GLMakie.GLFW

FPS = 60

function busywait(ns)
    time = time_ns()
    while time_ns() - time < ns; end
end

px = GLFW.GetVideoMode(GLFW.GetPrimaryMonitor()).width
py = GLFW.GetVideoMode(GLFW.GetPrimaryMonitor()).height
window_size = (px, py)

scene = Scene(size=window_size)

campixel!(scene)

pts = Observable([Point2(rand.((1:px, 1:py))) for i in 1:10^5])

scatter!(scene, pts,
        marker = GLMakie.FastPixel(),
        markersize = 2,
        color = :black
)

screen = GLMakie.Screen(scene; start_renderloop=false, focus_on_show=true)
glscreen = screen.glscreen

terminate = Ref{Bool}(false)
on(events(scene).keyboardbutton) do button
    println("Test KEY:", button.key, " | delete:", Keyboard.delete)
    if button.key == Keyboard.delete
        terminate[] = true
    end
end

while !terminate[]
    time = time_ns()

    for i in eachindex(pts[])
        pts[][i] = abs.(pts[][i] + Point2(rand.((-2:2, -2:2))))
    end
    notify(pts)

    GLMakie.pollevents(screen)
    GLMakie.render_frame(screen)
    GLFW.SwapBuffers(glscreen)

    if  time + 10^9/FPS - time_ns() < 0
        println("Can't keep up!, FPS=", round(10^9/(time_ns() - time)))
    end
    busywait(time + 10^9/FPS - time_ns())
end

close(screen)