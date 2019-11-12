using Test
using Random

include(string(@__DIR__)*"/../src/main.jl")

@testset "functions.jl" begin
    type_fichier = "X"
    nom_fichier = INSTANCES[type_fichier][end]
    instance = parser(nom_fichier, type_fichier)
    solution = greedy(instance)
    @testset "moves" begin
        @testset "move_exchange!" begin
            solution_test = deepcopy(solution)
            move_exchange!(solution_test, 1, solution_test.n, instance)
            move_exchange!(solution_test, 1, solution_test.n, instance)
            # This shouldn't have changed anything
            @test solution.n == solution_test.n
            @test solution.sequence == solution_test.sequence
            @test solution.M1 == solution_test.M1
            @test solution.M2 == solution_test.M2
            @test solution.M3 == solution_test.M3
        end;

        @testset "move_exchange! and update_matrices!" begin
            solution_test = deepcopy(solution)
            move_exchange!(solution_test, 1, solution_test.n, instance)
            solution_test_test = deepcopy(solution_test)
            update_matrices!(solution_test_test, solution_test_test.n, instance)
            @test solution_test.n == solution_test_test.n
            @test solution_test.sequence == solution_test_test.sequence
            @test solution_test.M1 == solution_test_test.M1
            @test solution_test.M2 == solution_test_test.M2
            @test solution_test.M3 == solution_test_test.M3

            solution_test = deepcopy(solution)
            pos = round(Int, solution_test.n / 2, RoundUp)
            move_exchange!(solution_test, pos-1, pos, instance)
            solution_test_test = deepcopy(solution_test)
            update_matrices!(solution_test_test, solution_test_test.n, instance)
            @test solution_test.n == solution_test_test.n
            @test solution_test.sequence == solution_test_test.sequence
            @test solution_test.M1 == solution_test_test.M1
            @test solution_test.M2 == solution_test_test.M2
            @test solution_test.M3 == solution_test_test.M3
        end;

        @testset "move_insertion!" begin
            solution_test = deepcopy(solution)
            move_insertion!(solution_test, 1, 1, instance)
            # This shouldn't have changed anything
            @test solution.n == solution_test.n
            @test solution.sequence == solution_test.sequence
            @test solution.M1 == solution_test.M1
            @test solution.M2 == solution_test.M2
            @test solution.M3 == solution_test.M3

            solution_test = deepcopy(solution)
            move_insertion!(solution_test, solution_test.n, solution_test.n, instance)
            # This shouldn't have changed anything
            @test solution.n == solution_test.n
            @test solution.sequence == solution_test.sequence
            @test solution.M1 == solution_test.M1
            @test solution.M2 == solution_test.M2
            @test solution.M3 == solution_test.M3

            solution_test = deepcopy(solution)
            pos = round(Int, solution_test.n / 2, RoundUp)
            move_insertion!(solution_test, pos, pos, instance)
            # This shouldn't have changed anything
            @test solution.n == solution_test.n
            @test solution.sequence == solution_test.sequence
            @test solution.M1 == solution_test.M1
            @test solution.M2 == solution_test.M2
            @test solution.M3 == solution_test.M3
        end;

        @testset "move_insertion! and update_matrices!" begin
            solution_test = deepcopy(solution)
            for _ in 1:5
                move_insertion!(solution_test, rand(1:solution_test.n), rand(1:solution_test.n), instance)
            end
            solution_test_test = deepcopy(solution_test)
            update_matrices!(solution_test_test, solution_test_test.n, instance)
            @test solution_test.n == solution_test_test.n
            @test solution_test.sequence == solution_test_test.sequence
            @test solution_test.M1 == solution_test_test.M1
            @test solution_test.M2 == solution_test_test.M2
            @test solution_test.M3 == solution_test_test.M3

            solution_test = deepcopy(solution)
            move_insertion!(solution_test, rand(1:solution_test.n), solution_test.n, instance)
            solution_test_test = deepcopy(solution_test)
            update_matrices!(solution_test_test, solution_test_test.n, instance)
            @test solution_test.n == solution_test_test.n
            @test solution_test.sequence == solution_test_test.sequence
            @test solution_test.M1 == solution_test_test.M1
            @test solution_test.M2 == solution_test_test.M2
            @test solution_test.M3 == solution_test_test.M3

            solution_test = deepcopy(solution)
            move_insertion!(solution_test, rand(1:solution_test.n), 1, instance)
            solution_test_test = deepcopy(solution_test)
            update_matrices!(solution_test_test, solution_test_test.n, instance)
            @test solution_test.n == solution_test_test.n
            @test solution_test.sequence == solution_test_test.sequence
            @test solution_test.M1 == solution_test_test.M1
            @test solution_test.M2 == solution_test_test.M2
            @test solution_test.M3 == solution_test_test.M3
        end;
    end;

    @testset "costs" begin
        @testset "cost_move_exchange!" begin
            #TODO
        end;

        @testset "cost_move_insertion!" begin
            #TODO
        end;
    end;
end;

@testset "solution.jl" begin
    type_fichier = "A"
    nom_fichier = INSTANCES[type_fichier][1]
    instance = parser(nom_fichier, type_fichier)
    solution = greedy(instance)
    @testset "update_matrices!" begin
        solution_test = deepcopy(solution)
        update_matrices!(solution_test, solution_test.n, instance)
        @test solution.n == solution_test.n
        @test solution.sequence == solution_test.sequence
        @test solution.M1 == solution_test.M1
        @test solution.M2 == solution_test.M2
        @test solution.M3 == solution_test.M3
    end;
end;

@testset "vns_lprc.jl" begin
    type_fichier = "A"
    nom_fichier = INSTANCES[type_fichier][1]
    instance = parser(nom_fichier, type_fichier)
    solution_greedy = greedy(instance)
    solution_vns_LPRC = VNS_LPRC(solution_greedy, instance)

    @test solution_greedy.n == solution_vns_LPRC.n
    @test cost_VNS_LPRC(solution_vns_LPRC, instance) <= cost_VNS_LPRC(solution_greedy, instance)
end;
