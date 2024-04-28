@testset "iterables" begin
    # Test List and ThreadedList
    list = ParticLas.ThreadedList(Int64, 10, 3)

    for i in 1:3
        my_list = ParticLas.local_list(list, i)

        for k in 1:5
            push!(my_list, k + 5 * (i - 1))
        end

    end
    @test collect(1:15) == collect(item for item in list)

    my_list = ParticLas.local_list(list, 1)
    delete!(my_list, 4)
    @test collect(my_list[i] for i in eachindex(my_list)) == [5, 3, 2, 1]

    ParticLas.clear!(my_list)
    @test length(my_list) == 0

    for i in 1:10
        push!(my_list, i)
    end
    @test push!(my_list, 4) == -1

    # Test ThreadedMatrix
    m = ParticLas.ThreadedMatrix(1, (10, 20), 5)
    for i in 1:10, j in 1:20
        m._items[i, j] = i + (j - 1) * 10
    end

    @test m[2, 5] == 42

    locals = collect(m[idx] for i in 1:5 for idx in ParticLas.local_indices(m, i))

    max_diff = 0
    for i in 1:5, j in i+1:5
        max_diff = max(max_diff, abs(length(locals[i]) - length(locals[j])))
    end
    @test max_diff < 2

    @test sort(vcat(locals...)) == collect(1:200)
end