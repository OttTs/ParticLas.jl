
chnl = Channel{Vector{Int8}}(1)

function putter(chnl, y)
    sleep(3)
    @time put!(chnl, y)
end

function getter(chnl)
    println(take!(chnl))
end

function main()
    y = Int8[1,2,3]
    Threads.@spawn getter(chnl)
    Threads.@spawn putter(chnl, y)
    sleep(0.3)
    Threads.@spawn getter(chnl)
    Threads.@spawn putter(chnl, y)
    sleep(0.3)
    Threads.@spawn getter(chnl)
    Threads.@spawn putter(chnl, y)
    sleep(0.3)
    Threads.@spawn getter(chnl)
    Threads.@spawn putter(chnl, y)
    sleep(0.3)
    Threads.@spawn getter(chnl)
    Threads.@spawn putter(chnl, y)
end

main()
