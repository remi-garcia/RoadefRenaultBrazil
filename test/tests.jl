using Test

@testset "solution.jl" begin
    type_fichier = "A"
    nom_fichier = INSTANCES[type_fichier][1]
    instance = parser(nom_fichier, type_fichier)
    solution = greedy(instance)
    @testset "update_matrices!" begin
        solution_test = deepcopy(solution)
        update_matrices!(solution_test, solution_test.n, instance)
        @test solution.n == solution2.n
        @test solution.sequence == solution2.sequence
        @test solution.M1 == solution2.M1
        @test solution.M2 == solution2.M2
        @test solution.M3 == solution2.M3
    end;
end;
