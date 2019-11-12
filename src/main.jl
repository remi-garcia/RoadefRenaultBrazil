#-------------------------------------------------------------------------------
# File: main.jl
# Description: VNS for the RENAULT Roadef 2005 challenge
#   inspired by work of
#   Celso C. Ribeiro, Daniel Aloise, Thiago F. Noronha,
#   Caroline Rocha, Sebastián Urrutia
#
# Date: October 31, 2019
# Author: Jonathan Fontaine, Killian Fretaud, Rémi Garcia,
#         Boualem Lamraoui, Benoît Le Badezet, Benoit Loger
#-------------------------------------------------------------------------------

# Complete strategy can be summerize as follow:
#
#   (1) Use a constructive heuristic to find an initial solution.
#   (2) Use an improvement heuristic to optimize the first objective.
#   (3) Use an improvement heuristic to optimize the second objective.
#   (4) Use a repair heuristic to make the current solution feasible.
#   (5) Use an improvement heuristic to optimize the third objective.
#

include("parser.jl")
include("solution.jl")
include("functions.jl")
include("constants.jl")
include("greedy.jl")
include("vns_lprc.jl")
include("vns_pcc.jl")

include("for-test.jl")

function main()

    type = ["A"]#, "B"]

    # Instance and initiale solution
    for instance_type in type#["A", "B", "X"]
        name = [INSTANCES[instance_type][1], INSTANCES[instance_type][end]]
        for instance_name in name#INSTANCES[instance_type]

            start_time = time_ns()
            println("\t====================")
            println("Instance ",instance_type,"/",instance_name)

            # Parser
            instance = parser(instance_name, instance_type)
            println("Loaded...")

            # Greedy
            solution = greedy(instance)
            println("Initial solution created...")
            print_cost(solution, instance)

            for j in 1:(instance.nb_HPRC+instance.nb_LPRC)
                print(" ", instance.RC_flag[8, j])
            end

            for i in 8:7
                for j in i:instance.nb_cars
                    c1 = cost_move_insertion(solution, i, instance, 3)
                    c2 = TEST_cost_move_insertion(solution, i, instance, 3)
                    if ((c1[j,1] != c2[j,1]) || (c1[j,2] != c2[j,2]))
                        println("FAIL : ", c1[j, :], " vs. ", c2[j, :], " \t\t - insert ", i, " at ", j)
                    end
                end
            end

            # print("Solution improved with ILS_HPRC : ")
            # solution = ILS_HPRC(solution, instance)
            # println("done..")
            # print_cost(solution, instance)

            # println(instance.nb_late_prec_day)

            # print("Solution improved with VNS_LPRC : ")
            # solution = VNS_LPRC(solution, instance)
            # println("done..")
            # print_cost(solution, instance)

            # print("Solution improved with VNS_PCC : ")
            # solution = VNS_PCC(solution, instance, start_time)
            # println("done..")
            # print_cost(solution, instance)

            println()
            println()
        end
    end
end
