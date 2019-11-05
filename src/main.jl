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

function main()

<<<<<<< HEAD
    type = ["A","B","X"]

    # Instance and initiale solution
    for instance_type in type#["A", "B", "X"]
        name = [INSTANCES[instance_type][i] for i in 1:length(INSTANCES[instance_type])]
=======
    type = ["A", "B"]

    # Instance and initiale solution
    for instance_type in type#["A", "B", "X"]
        name = [INSTANCES[instance_type][1], INSTANCES[instance_type][end]]
>>>>>>> master
        for instance_name in name#INSTANCES[instance_type]
            start_time = time_ns()
            println("Instance ",instance_type,"/",instance_name)

            # Parser
            instance = parser(instance_name, instance_type)
            println("Loaded...")

            # Greedy
            solution = greedy(instance)
            println("Initial solution created...")

            #solution = VNS_LPRC(solution, instance)
            #println("Solution improved with VNS_LPRC")

<<<<<<< HEAD
            #solution = VNS_PCC(solution, instance, start_time)
            println("Solution improved with VNS_PCC")
            repair!(solution, instance)
            #println(solution.sequence)
=======
            solution = VNS_PCC(solution, instance, start_time)
            println("Solution improved with VNS_PCC")

            println(solution.sequence)
>>>>>>> master
            println()
        end
    end
end
