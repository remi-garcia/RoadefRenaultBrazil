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
    for instance_type in ["A", "B", "X"]#type#
        #name = [INSTANCES[instance_type][1], INSTANCES[instance_type][end]]
        #name = [INSTANCES[instance_type][1], INSTANCES[instance_type][2], INSTANCES[instance_type][3], INSTANCES[instance_type][4], INSTANCES[instance_type][end]]
        for instance_name in INSTANCES[instance_type]#name

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

            # for j in 1:(instance.nb_HPRC+instance.nb_LPRC)
            #     print(" ", instance.RC_flag[8, j])
            # end

            # Seems okay but don't know why
            for i in 1:instance.nb_cars-1
                for j in i:instance.nb_cars


                    ####
                    #### TEST COST MOVE EXCHANGE
                    ####

                    # c1 = TEST_cost_move_exchange(solution,  i, j, instance, 3)
                    # c2 = cost_move_exchange(solution, i, j, instance, 3)
                    # if ((c1[1] != c2[1]) || (c1[2] != c2[2]))
                    #     println("FAIL : ", c1, " vs. ", c2, " \t\t - exhange ", i, " and ", j)
                    # end
                    #

                    ####
                    #### TEST MOVE EXCHANGE
                    ####

                    # s1 = deepcopy(solution)
                    # s1 = move_exchange!(s1, i, j, instance)
                    # s2 = deepcopy(solution)
                    # s2 = TEST_move_exchange!(s2, i, j, instance)
                    #
                    # for I in 1:s1.n
                    #     for J in 1:instance.nb_HPRC+instance.nb_LPRC
                    #         if ((s1.M1[J, I] != s2.M1[J, I]))
                    #             println("FAIL : on M1 - case ", I, " , ", J)
                    #         end
                    #     end
                    # end
                    #
                    #
                    # for I in 1:s1.n
                    #     for J in 1:instance.nb_HPRC+instance.nb_LPRC
                    #         if ((s1.M2[J, I] != s2.M2[J, I]))
                    #             println("FAIL : on M2 - case ", I, " , ", J)
                    #         end
                    #     end
                    # end
                    #
                    # for I in 1:s1.n
                    #     for J in 1:instance.nb_HPRC+instance.nb_LPRC
                    #         if ((s1.M3[J, I] != s2.M3[J, I]))
                    #             println("FAIL : on M2 - case ", I, " , ", J)
                    #         end
                    #     end
                    # end
                    #
                    # c1 = cost(s1, instance, 3)
                    # c2 = cost(s2, instance, 3)
                    # if ((c1[1] != c2[1]) || (c1[2] != c2[2]))
                    #     println("FAIL : ", c1, " vs. ", c2, " \t\t - exchange ", i, " and ", j)
                    # end
                end
            end

            for i in instance.nb_late_prec_day+1:instance.nb_cars#instance.nb_late_prec_day+1

                ####
                #### TEST COST MOVE INSERTION
                ####


                c1 = TEST_cost_move_insertion(solution,  i, instance, 3)

                c2 = cost_move_insertion(solution, i, instance, 3)
                for j in instance.nb_late_prec_day+1:instance.nb_cars#instance.nb_late_prec_day+1:instance.nb_late_prec_day+1#1:solution.n
                    if ((c1[j,1] != c2[j,1]) || (c1[j,2] != c2[j,2]))
                        println("FAIL : ", c1[j,:], " vs. ", c2[j,:], " \t\t - insert ", i, " at ", j)
                    #else
                    #    println("SUCC : ", c1[j,:], " vs. ", c2[j,:], " \t\t - insert ", i, " at ", j)
                    end
                end




                ####
                #### TEST MOVE INSERTION
                ####

                # s1 = deepcopy(solution)
                # s1 = move_insertion!(s1, i, instance)
                # s2 = deepcopy(solution)
                # s2 = TEST_move_insertion!(s2, i, instance)
                # for j in i+1:solution.n

                    # if ((s1.M1[j, i] != s2.M1[j, i]))
                    #     println("FAIL : on M1 - case ", i, " , ", j)
                    # end
                    #
                    # for i in 1:s1.n
                    #     for j in 1:instance.nb_HPRC+instance.nb_LPRC
                    #         if ((s1.M2[j, i] != s2.M2[j, i]))
                    #             println("FAIL : on M2 - case ", i, " , ", j)
                    #         end
                    #     end
                    # end
                    #
                    # for i in 1:s1.n
                    #     for j in 1:instance.nb_HPRC+instance.nb_LPRC
                    #         if ((s1.M3[j, i] != s2.M3[j, i]))
                    #             println("FAIL : on M2 - case ", i, " , ", j)
                    #         end
                    #     end
                    # end
                    #
                    # c1 = cost(s1, instance, 3)
                    # c2 = cost(s2, instance, 3)
                    # if ((c1[1] != c2[1]) || (c1[2] != c2[2]))
                    #     println("FAIL : ", c1, " vs. ", c2, " \t\t - exhange ", i, " and ", j)
                    # end
                # end

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
