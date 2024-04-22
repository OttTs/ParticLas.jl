# TODO Test mesh iterator


@testset "mesh_iterator" begin
    num_cells = (142, 43)#(rand(30:180), rand(20:100))
    num_threads = 7#rand(1:10)

    indices = [CartesianIndex[] for _ in 1:num_threads]
    for id = 1:num_threads
        for i in ParticLas.cell_indices(num_cells, num_threads, id)
            push!(indices[id], i)
        end
    end

    max_diff = 0
    for id1 = 1:num_threads
        for id2 = (id1+1):num_threads
            max_diff = max(max_diff, abs(length(indices[id1]) - length(indices[id2])))
        end
    end
    @test max_diff ≤ 1

    indices = vcat(indices...)
    sort!(indices)
    @test all(indices .== vcat(collect(CartesianIndices(num_cells))...))
end