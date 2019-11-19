using Test

include(string(@__DIR__)*"/../src/main.jl")

@testset "functions.jl" begin
    type_fichier = "X"
    nom_fichier = INSTANCES[type_fichier][end]
    instance = parser(nom_fichier, type_fichier)
    solution = greedy(instance)
    @testset "move_exchange!" begin
        solution_test = deepcopy(solution)
        move_exchange!(solution_test, 1, instance.nb_cars, instance)
        move_exchange!(solution_test, 1, instance.nb_cars, instance)
        # This shouldn't have changed anything
        @test solution.sequence == solution_test.sequence
        @test solution.M1 == solution_test.M1
        @test solution.M2 == solution_test.M2
        @test solution.M3 == solution_test.M3
    end;
    @testset "move_exchange! and update_matrices!" begin
        solution_test = deepcopy(solution)
        move_exchange!(solution_test, 1, instance.nb_cars, instance)
        solution_test_test = deepcopy(solution_test)
        update_matrices!(solution_test_test, instance.nb_cars, instance)
        # This shouldn't have changed anything
        @test solution_test.sequence == solution_test_test.sequence
        @test solution_test.M1 == solution_test_test.M1
        @test solution_test.M2 == solution_test_test.M2
        @test solution_test.M3 == solution_test_test.M3
    end;
    @testset "move_insertion!" begin
        solution_test = deepcopy(solution)
        move_insertion!(solution_test, 1, 1, instance)
        # This shouldn't have changed anything
        @test solution.sequence == solution_test.sequence
        @test solution.M1 == solution_test.M1
        @test solution.M2 == solution_test.M2
        @test solution.M3 == solution_test.M3

        solution_test = deepcopy(solution)
        move_insertion!(solution_test, instance.nb_cars, instance.nb_cars, instance)
        # This shouldn't have changed anything
        @test solution.sequence == solution_test.sequence
        @test solution.M1 == solution_test.M1
        @test solution.M2 == solution_test.M2
        @test solution.M3 == solution_test.M3

        solution_test = deepcopy(solution)
        pos = round(Int, instance.nb_cars / 2, RoundUp)
        move_insertion!(solution_test, pos, pos, instance)
        # This shouldn't have changed anything
        @test solution.sequence == solution_test.sequence
        @test solution.M1 == solution_test.M1
        @test solution.M2 == solution_test.M2
        @test solution.M3 == solution_test.M3
    end;
    @testset "cost_move_exchange!" begin
        solution_test = deepcopy(solution)
        delta = cost_move_exchange(solution, 1, instance.nb_cars, instance, 3)
        move_exchange!(solution_test, 1, instance.nb_cars, instance)
        delta_test = cost_move_exchange(solution_test, 1, solution_test.n, instance, 3)
        # This shouldn't be opposite costs
        @test delta == -delta_test

        solution_test = deepcopy(solution)
        delta = cost_move_exchange(solution, 1, instance.nb_cars, instance, 3)
        delta_only_First = cost_move_exchange(solution, 1, instance.nb_cars, instance, 1)
        # Only one first objective should be less than on first+second
        @test delta[1] == delta_only_First[1]
    end;
end;

@testset "solution.jl" begin
    type_fichier = "A"
    nom_fichier = INSTANCES[type_fichier][1]
    instance = parser(nom_fichier, type_fichier)
    solution = greedy(instance)
    @testset "update_matrices!" begin
        solution_test = deepcopy(solution)
        update_matrices!(solution_test, instance.nb_cars, instance)
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

    @test cost_VNS_LPRC(solution_vns_LPRC, instance) <= cost_VNS_LPRC(solution_greedy, instance)
end;
