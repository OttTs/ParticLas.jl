@testset "mesh" begin
    mesh = ParticLas.SimMesh((2, 1), (120, 60), 5)
    @test all(ParticLas.cellsize(mesh) .≈ 1/60)
    @test ParticLas.cellvolume(mesh) ≈ 1/3600
    @test ParticLas.num_cells(mesh) == (120, 60)
    @test ParticLas.get_index((41.2/60, 56.99/60), mesh) == CartesianIndex(42, 57)
    wall = ParticLas.Wall((41.2/60, 56.99/60), (76.4/60, 29.1/60))
    ParticLas.add!(mesh, wall)
    @test begin
        for i in CartesianIndices(mesh.cells._items)
            if 42 < i[1] < 77 && 30 <= i[2] <= 57
                length(mesh.cells[i].walls) == 0 && return false
            else
                length(mesh.cells[i].walls) > 0 && return false
            end
        end
        return true
    end
end
