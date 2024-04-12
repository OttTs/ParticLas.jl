# This is a test for a simple screen using GLMakie

using GLMakie
using GLMakie.GLFW

FPS = 60
Npts = 10^6
Nworkers = 1

function busywait(ns)
    time = time_ns()
    while time_ns() - time < ns; end
end

## Communication with worker threads ------------------------------------------------------
struct DataContainer
    data::Vector{Point2f}
    worker_offsets::Vector{Int64}
    worker_done::Vector{Bool}
    function DataContainer(data, worker_offsets)
        return new(
            data,
            worker_offsets,
            zeros(Bool, length(worker_offsets))
        )
    end
end

function waitfor(c::DataContainer; timeout=1000)
    time = time_ns()
    while !all(c.worker_done)
        busywait(0)#10^8)
        time_ns() - time > timeout*10^6 && return false
        #println("GUI waiting..., status=", c.worker_done)
    end
    return true
end

function requestdata(c::DataContainer)
    c.worker_done .= false
end

function senddata!(c::DataContainer, data, id)
    #println("Worker ", id, " sending data! Done=", c.worker_done[id])
    while c.worker_done[id]
        busywait(0)#10^8)
    end

    write(string("myfile-",id,".txt"),string("offset..."))

    #println("Do")
    offset = c.worker_offsets[id]
    #println(offset)
    for i in eachindex(data)
        c.data[i + offset] = data[i]
    end
    #println("Done")
    write(string("myfile-",id,".txt"),string("done..."))

    c.worker_done[id] = true
    #println("Worker ", id, " sending data done!")
end

## Setup screen ---------------------------------------------------------------------------
px = GLFW.GetVideoMode(GLFW.GetPrimaryMonitor()).width
py = GLFW.GetVideoMode(GLFW.GetPrimaryMonitor()).height
window_size = (px, py)

scene = Scene(size=window_size)

campixel!(scene)

pts = [Point2(rand.((1:px, 1:py))) for i in 1:Npts]

sc = scatter!(scene, pts,
        marker = GLMakie.FastPixel(),
        markersize = 1,
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

## Setup communication
Ni = Npts ÷ Nworkers
comm = DataContainer(copy(pts), collect(((1:Nworkers).-1)*Ni))
println(comm.data[1])

function workerloop(comm, pts, id)
    time = time_ns()
    while time_ns() - time < 30*10^9 # Run for 30 sec
        #println("In workerloop... worker ", id)
        for i in eachindex(pts)
            pts[i] = abs.(pts[i] + Point2f(rand.((-2:2, -2:2))))
        end

        write(string("myfile-",id,".txt"),string("Sending..."))

        senddata!(comm, pts, id)
        GC.safepoint()
    end
end

function renderloop(screen, pts, comm)
    while !terminate[]
        time = time_ns()

        success = waitfor(comm; timeout=1000)

        wait_time = time_ns()

        if success
            for i in eachindex(pts[])
                pts[][i] = comm.data[i]
            end

            requestdata(comm)
        else
            println("WTF")
        end


        notify(pts)

        cpu_time = time_ns()

        GLMakie.pollevents(screen)
        GLMakie.render_frame(screen)
        GLFW.SwapBuffers(glscreen)

        gpu_time = time_ns()

        if  time + 10^9/FPS - gpu_time < 0
            println(
                "FPS=", round(10^9/(time_ns() - time)),
                " | Workers:", round((wait_time - time)/(gpu_time - time)*100; digits=2),
                " | CPU:", round((cpu_time - wait_time)/(gpu_time - time)*100; digits=2),
                " | GPU:", round((gpu_time - cpu_time)/(gpu_time - time)*100; digits=2),
            )
            println((cpu_time - time)/10^9)
        end
        busywait(time + 10^9/FPS - time_ns())
    end

    close(screen)
end

# Run workers
for i in 1:Nworkers
    start = comm.worker_offsets[i] + 1
    stop = i == Nworkers ? length(pts) : comm.worker_offsets[i+1]
    Threads.@spawn workerloop(comm, pts[start:stop], i)
end

renderloop(screen, sc[1], comm)