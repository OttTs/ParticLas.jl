# This is a test for a simple screen using GLMakie

using GLMakie
using GLMakie.GLFW

FPS = 60
Npts = 10^6
Nworkers = 4

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

function waitfor(c::DataContainer, term; timeout=1000)
    time = time_ns()
    while !all(c.worker_done)
        busywait(0)
        term[] && return
        time_ns() - time > timeout*10^6 && return false
    end
    return true
end

function requestdata(c::DataContainer)
    c.worker_done .= false
end

function senddata!(c::DataContainer, data, id, term)
    while c.worker_done[id]
        busywait(0)
        term[] && return
    end


    offset = c.worker_offsets[id]
    for i in eachindex(data)
        c.data[i + offset] = data[i]
    end

    c.worker_done[id] = true
end

## Setup screen ---------------------------------------------------------------------------
px = GLFW.GetVideoMode(GLFW.GetPrimaryMonitor()).width
py = GLFW.GetVideoMode(GLFW.GetPrimaryMonitor()).height
window_size = (1920, 1080)#(px, py)

scene = Scene(size=window_size)

campixel!(scene)

pts = [Point2f(100, 200) for i in 1:Npts]

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

function workerloop(term, comm, pts, id, maxpos)
    vels = Point2f[]
    for i in eachindex(pts)
        r = 0.5 + rand()
        phi = 2π * rand()
        vx = 3 + sin(phi) * r
        vy = 2 + cos(phi) * r
        push!(vels, Point2f(vx, vy))
    end

    while !term[]
        for i in eachindex(pts)
            pts[i] += vels[i]
            vels[i] = vels[i] .* (0 .< pts[i] .< maxpos) - vels[i] .* (pts[i] .<= 0) - vels[i]               .* (pts[i] .>= maxpos)
            pts[i]  = pts[i]  .* (0 .< pts[i] .< maxpos) - pts[i]  .* (pts[i] .<= 0) + (2 * maxpos - pts[i]) .* (pts[i] .>= maxpos)
        end

        senddata!(comm, pts, id, term)

        GC.safepoint()
    end
end

function renderloop(screen, pts, comm, term)
    while !term[]
        #println(1)
        time = time_ns()
        #println(2)
        success = waitfor(comm, term; timeout=1000)
        #println(3)
        wait_time = time_ns()
        #println(4)
        if success
            #pts.val = comm.data
            pts[] = comm.data
            #Threads.@threads for i in eachindex(comm.data)
            #    pts[][i] = comm.data[i]
            #end
            
            cpu1_time = time_ns()
            #notify(pts)
            #pts[] = comm.data
            requestdata(comm)
        else
            println("WTF")
        end
        #println(5)
        cpu_time = time_ns()
        GLMakie.pollevents(screen)
        gpu1_time = time_ns()
        GLMakie.render_frame(screen)
        gpu2_time = time_ns()
        GLFW.SwapBuffers(glscreen)
        gpu_time = time_ns()
        #println(6)
        if  time + 10^9/FPS - gpu_time < 0
            println(
                "FPS=", round(10^9/(time_ns() - time)),
                " | Workers:", round((wait_time - time)/(gpu_time - time)*100; digits=2),
                " | CPU:", round((cpu_time - wait_time)/(gpu_time - time)*100; digits=2),
                " | notify:", round((cpu_time - cpu1_time)/(gpu_time - time)*100; digits=2),
                " | GPU1:", round((gpu1_time - cpu_time)/(gpu_time - time)*100; digits=2),
                " | GPU2:", round((gpu2_time - gpu1_time)/(gpu_time - time)*100; digits=2),
                " | GPU3:", round((gpu_time - gpu2_time)/(gpu_time - time)*100; digits=2),
            )
            #println((cpu2_time - time)/10^9)
        end
        busywait(time + 10^9/FPS - time_ns())
    end
    close(screen)
end

# Run workers
for i in 1:Nworkers
    start = comm.worker_offsets[i] + 1
    stop = i == Nworkers ? length(pts) : comm.worker_offsets[i+1]
    Threads.@spawn workerloop(terminate, comm, pts[start:stop], i, Point2(window_size))
end

# 40 - 60
# This ignores the apply_transform... (Swap back when changing the cam to the physical lengths)
renderloop(screen, sc[1].listeners[1].second.result, comm, terminate)
#renderloop(screen, sc[1], comm)