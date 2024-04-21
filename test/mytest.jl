
function busywait(ns)
    time = time_ns()
    while time_ns() - time < ns; end
end

function wait_for_change(waitit, medone, i)
    while true
        time = time_ns()
        iter = 0
        while waitit[]
            iter += 1
            if time_ns() > time + 10^10
                write(string(Threads.threadid(), ".txt") , string("FAILED, ", iter))
                break
            end
        end
        medone[i] = true
    end
end

function change_variable(waitit, medone)
    #println("Changing variable")
    #Threads.atomic_xchg!(answer, Int8(42))
    waitit[] = false

    time = time_ns()
    iter = 0
    while !all(medone)
        iter += 1
        if time_ns() > time + 10^10
            write("changer.txt" , string("FAILED, ", iter))
            break
        end
    end

    waitit[] = true
end

waitit = Ref{Bool}(true)#Threads.Atomic{Int8}(0)
medone = zeros(Bool, 7)

for j in 1:7
    Threads.@spawn :default wait_for_change(waitit, medone, j)
end

for i in 1:10000
    #println("Changing...")
    change_variable(waitit, medone)
    println(i)
end