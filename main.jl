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
    type = ["X"]#["A", "B", "X"]

    # Instance and initiale solution
    for instance_type in type#["A", "B", "X"]
        for instance_name in RRB.INSTANCES[instance_type]#[RRB.INSTANCES[instance_type][1]]
        # names = [RRB.INSTANCES[instance_type][1], RRB.INSTANCES[instance_type][end]]
        # for instance_name in names
            GC.gc()
            @time begin
            start_time = time_ns()
            println("\t====================")
            println("Instance ", instance_type, "/", instance_name)

            # Parser
            @time instance = RRB.parser(instance_name, instance_type)
            println("Loaded...")

            costs = zeros(Int,5,3)

            # Greedy
            @time solution = RRB.greedy(instance)
            println("Initial solution created...")
            costs[1,:] = RRB.cost(solution, instance, 3)

            # ILS-HPRC
            @time solution = RRB.ILS_HPRC(solution, instance, start_time)
            println("Solution improved with ILS_HPRC")
            costs[2,:] = RRB.cost(solution, instance, 3)

            # VNS-LPRC
            @time solution = RRB.VNS_LPRC(solution, instance, start_time)
            println("Solution improved with VNS_LPRC")
            costs[3,:] = RRB.cost(solution, instance, 3)

            # print("[", instance.color_code[solution.sequence[1]])
            # for pos in 2:instance.nb_cars
            #     print(",", instance.color_code[solution.sequence[pos]])
            # end
            # println("]")
            #
            # print("[")
            # pos = 1
            # while pos <= instance.nb_cars
            #     print(solution.colors[pos].start,"(",solution.colors[pos].width,") ")
            #     pos += solution.colors[pos].width
            # end
            # println("]")

            # Repair
            @time RRB.initialize_batches!(solution, instance)
            @time RRB.repair!(solution, instance)
            println("Solution repaired")
            costs[4,:] = RRB.cost(solution, instance, 3)

            # VNS-PCC
            #@time solution = RRB.VNS_PCC(solution, instance, start_time)
            #println("Solution improved with VNS_PCC")
            costs[5,:] = RRB.cost(solution, instance, 3)

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
