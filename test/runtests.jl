using Test
using Random

import RoadefRenaultBrazil
const RRB = RoadefRenaultBrazil

@testset "move_exchange.jl" begin
    type_fichier = "A"
    nom_fichier = "024_38_3_EP_ENP_RAF"
    instance = RRB.parser(nom_fichier, type_fichier)
    solution = RRB.greedy(instance)
    @testset "move_exchange!" begin
        solution_test = deepcopy(solution)
        RRB.move_exchange!(solution_test, 1, instance.nb_cars, instance)
        RRB.move_exchange!(solution_test, 1, instance.nb_cars, instance)
        # This shouldn't have changed anything
        @test solution.sequence == solution_test.sequence
        @test solution.M1 == solution_test.M1
        @test solution.M2 == solution_test.M2
        @test solution.M3 == solution_test.M3
    end;

    @testset "move_exchange! and update_matrices!" begin
        solution_test = deepcopy(solution)
        RRB.move_exchange!(solution_test, 1, instance.nb_cars, instance)
        solution_test_test = deepcopy(solution_test)
        RRB.update_matrices!(solution_test_test, instance.nb_cars, instance)
        # This shouldn't have changed anything
        @test solution_test.sequence == solution_test_test.sequence
        @test solution_test.M1 == solution_test_test.M1
        @test solution_test.M2 == solution_test_test.M2
        @test solution_test.M3 == solution_test_test.M3

        solution_test = deepcopy(solution)
        pos = round(Int, instance.nb_cars / 2, RoundUp)
        RRB.move_exchange!(solution_test, pos-1, pos, instance)
        solution_test_test = deepcopy(solution_test)
        RRB.update_matrices!(solution_test_test, instance.nb_cars, instance)
        @test solution_test.sequence == solution_test_test.sequence
        @test solution_test.M1 == solution_test_test.M1
        @test solution_test.M2 == solution_test_test.M2
        @test solution_test.M3 == solution_test_test.M3
    end;

    @testset "cost_move_exchange!" begin
        #TODO
    end;
end;

@testset "move_insertion.jl" begin
    type_fichier = "A"
    nom_fichier = "024_38_3_EP_ENP_RAF"
    instance = RRB.parser(nom_fichier, type_fichier)
    solution = RRB.greedy(instance)
    @testset "move_insertion!" begin
        solution_test = deepcopy(solution)
        RRB.move_insertion!(solution_test, 1, 1, instance)
        # This shouldn't have changed anything
        @test solution.sequence == solution_test.sequence
        @test solution.M1 == solution_test.M1
        @test solution.M2 == solution_test.M2
        @test solution.M3 == solution_test.M3

        solution_test = deepcopy(solution)
        RRB.move_insertion!(solution_test, instance.nb_cars, instance.nb_cars, instance)
        # This shouldn't have changed anything
        @test solution.sequence == solution_test.sequence
        @test solution.M1 == solution_test.M1
        @test solution.M2 == solution_test.M2
        @test solution.M3 == solution_test.M3

        solution_test = deepcopy(solution)
        pos = round(Int, instance.nb_cars / 2, RoundUp)
        RRB.move_insertion!(solution_test, pos, pos, instance)
        # This shouldn't have changed anything
        @test solution.sequence == solution_test.sequence
        @test solution.M1 == solution_test.M1
        @test solution.M2 == solution_test.M2
        @test solution.M3 == solution_test.M3
    end;

    @testset "move_insertion! and update_matrices!" begin
        solution_test = deepcopy(solution)
        for _ in 1:5
            RRB.move_insertion!(solution_test, rand(1:instance.nb_cars), rand(1:instance.nb_cars), instance)
        end
        solution_test_test = deepcopy(solution_test)
        RRB.update_matrices!(solution_test_test, instance.nb_cars, instance)
        @test solution_test.sequence == solution_test_test.sequence
        @test solution_test.M1 == solution_test_test.M1
        @test solution_test.M2 == solution_test_test.M2
        @test solution_test.M3 == solution_test_test.M3

        solution_test = deepcopy(solution)
        RRB.move_insertion!(solution_test, rand(1:instance.nb_cars), instance.nb_cars, instance)
        solution_test_test = deepcopy(solution_test)
        RRB.update_matrices!(solution_test_test, instance.nb_cars, instance)
        @test solution_test.sequence == solution_test_test.sequence
        @test solution_test.M1 == solution_test_test.M1
        @test solution_test.M2 == solution_test_test.M2
        @test solution_test.M3 == solution_test_test.M3

        solution_test = deepcopy(solution)
        RRB.move_insertion!(solution_test, rand(1:instance.nb_cars), 1, instance)
        solution_test_test = deepcopy(solution_test)
        RRB.update_matrices!(solution_test_test, instance.nb_cars, instance)
        @test solution_test.sequence == solution_test_test.sequence
        @test solution_test.M1 == solution_test_test.M1
        @test solution_test.M2 == solution_test_test.M2
        @test solution_test.M3 == solution_test_test.M3
    end;

    @testset "cost_move_insertion!" begin
        #TODO
    end;
end;

@testset "solution.jl" begin
    type_fichier = "A"
    nom_fichier = "024_38_3_EP_ENP_RAF"
    instance = RRB.parser(nom_fichier, type_fichier)
    solution = RRB.greedy(instance)
    @testset "update_matrices!" begin
        solution_test = deepcopy(solution)
        RRB.update_matrices!(solution_test, instance.nb_cars, instance)
        @test solution.sequence == solution_test.sequence
        @test solution.M1 == solution_test.M1
        @test solution.M2 == solution_test.M2
        @test solution.M3 == solution_test.M3
    end;
end;

@testset "vns_lprc.jl" begin
    type_fichier = "A"
    nom_fichier = "024_38_3_EP_ENP_RAF"
    instance = RRB.parser(nom_fichier, type_fichier)
    solution_greedy = RRB.greedy(instance)
    solution_vns_LPRC = RRB.VNS_LPRC(solution_greedy, instance)

    @test RRB.cost_VNS_LPRC(solution_vns_LPRC, instance) <= RRB.cost_VNS_LPRC(solution_greedy, instance)
end;
