#-------------------------------------------------------------------------------
# File: main.jl
# Description: RENAULT Roadef 2005 challenge
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

import RoadefRenaultBrazil
const RRB = RoadefRenaultBrazil

function main()
    type = ["A", "B", "X"]#["B"]#

    # Instance and initiale solution
    for instance_type in type#["A", "B", "X"]
        #["035_ch1_EP_ENP_RAF_S22_J3", "035_ch1_EP_RAF_ENP_S22_J3", "035_ch1_RAF_EP_ENP_S22_J3"]
        for instance_name in RRB.INSTANCES[instance_type]#[RRB.INSTANCES[instance_type][1]]
        # names = [RRB.INSTANCES[instance_type][1], RRB.INSTANCES[instance_type][end]]
        # for instance_name in names
            GC.gc()
            @time begin
            start_time = time_ns()
            println("\t====================")
            println("Instance ", instance_type, "/", instance_name)

            # Parser
            tmp = @timed instance = RRB.parser(instance_name, instance_type)
            println("Loaded... \t" * string(tmp[2]))

            costs = zeros(Int,5,3)

            # Greedy
            tmp = @timed solution = RRB.greedy_pcc(instance)
            println("Initial solution created... \t" * string(tmp[2]))
            costs[1,:] = RRB.cost(solution, instance, 3)

            # Repair
            tmp = @timed RRB.initialize_batches!(solution, instance)
            tmp1 = @timed RRB.repair!(solution, instance)
            println("Solution repaired \t" * string(tmp[2])*" - "*string(tmp1[2]))
            costs[4,:] = RRB.cost(solution, instance, 3)

            # VNS-PCC
            tmp = @timed solution = RRB.VNS_PCC(solution, instance, start_time)
            println("Solution improved with VNS_PCC \t" * string(tmp[2]))
            costs[5,:] = RRB.cost(solution, instance, 3)

            if !RRB.is_solution_valid(solution, instance)
                println("Solution invalid (paint batch limit of ", instance.nb_paint_limitation,")")
                i = instance.nb_late_prec_day+1
                while i <= solution.length
                    if solution.colors[i].width > instance.nb_paint_limitation
                        println("Batch starting at ", solution.colors[i].start, " is ", solution.colors[i].width)
                    end
                    i = i + solution.colors[i].width
                end
            end
            println("\tGr. \tILS \tVNS_lp\trepair\tVNS_pc")
            println("HP \t", costs[1,1] ,"\t", costs[2,1] ,"\t", costs[3,1] ,"\t", costs[4,1], "\t", costs[5,1])
            println("LP \t", costs[1,2] ,"\t", costs[2,2] ,"\t", costs[3,2] ,"\t", costs[4,2], "\t", costs[5,2])
            println("PCC \t", costs[1,3] ,"\t", costs[2,3] ,"\t", costs[3,3] ,"\t", costs[4,3], "\t", costs[5,3])
            println()


            end #@time
            println()
            println()
        end
    end
end
