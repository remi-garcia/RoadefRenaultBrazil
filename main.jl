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

import RoadefRenaultLocalSearch
const RRLS = RoadefRenaultLocalSearch

function main()
    type = ["A", "B"]

    # Instance and initiale solution
    for instance_type in type#["A", "B", "X"]
        name = [RRLS.INSTANCES[instance_type][1], RRLS.INSTANCES[instance_type][end]]
        for instance_name in name#INSTANCES[instance_type]
            start_time = time_ns()
            println("Instance ", instance_type, "/", instance_name)

            # Parser
            instance = RRLS.parser(instance_name, instance_type)
            println("Loaded...")

            # Greedy
            solution = RRLS.greedy(instance)
            println("Initial solution created...")

            #solution = VNS_LPRC(solution, instance)
            #println("Solution improved with VNS_LPRC")

            solution = RRLS.VNS_PCC(solution, instance, start_time)
            println("Solution improved with VNS_PCC")

            println(solution.sequence)
            println()
        end
    end
end
