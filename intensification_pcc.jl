#-------------------------------------------------------------------------------
# File: intensification_PCC.jl
# Description: This files contains all function that are used in intensification_PCC
# Date: October 31, 2019
# Author: Jonathan Fontaine, Killian Fretaud, Rémi Garcia,
#         Boualem Lamraoui, Benoît Le Badezet, Benoit Loger
#-------------------------------------------------------------------------------
include("parser.jl")
include("solution.jl")
include("functions.jl")
include("constants.jl")
include("greedy.jl")

#=if we have a move  which does not violate our color_constraint
    move_exchange!(instance, solution)
    move_insertion!(instance, solution)
    cost_move_exchange((solution, car_pos_a, car_pos_b, instance, 3)
    cost_move_exchange((solution, car_pos_a, car_pos_b, instance, 3)
then cost_color should be calculated :
nb_PCC_violated = 0
and every time we apply an move ,nb_PCC_violated += 1
then our  cost_move should be = cost_move + cost_color
Remark we sould update cost_move_exchange() in function.jl
=#
function cost_PCC(solution::Solution, instance::Instance)
    cost=cost_VNS_LPRC(solution, instance)+WEIGHTS_OBJECTIVE_FUNCTION[3] * nb_PCC_violated
    return cost
end


#=
The intensification phase is quite similar to those previously presented. The only
difference is that all objectives are simultaneously considered. An intensification phase
 is performed whenever the type of perturbation is changed.
=#


# Apply two local search, first one with insertion move, and the second one with exchange move.
function intensification_PCC!(solution::Solution, instance::Instance)
    localSearch_intensification_PCC!(solution, PCC_ALPHA_PERTURBATION, cost_move_insertion, move_insertion!, instance)
    localSearch_intensification_PCC!(solution, PCC_ALPHA_PERTURBATION, cost_move_exchange, move_exchange!, instance)
    return solution
end

function localSearch_intensification_PCC!(solution::Solution, alpha::Int, cost_move::Function, move!::Function, instance::Instance)
    # useful variable
    b0 = instance.nb_late_prec_day+1
    nb_non_improved = 0
    while nb_non_improved < alpha
        phi = cost_PCC(solution, instance)
        for i in b0:solution.n
            best_delta = 0
            list = Array{Int, 1}()
            for j in b0:solution.n
                delta = cost_move(solution, i, j, instance, 3)
                if delta < best_delta
                    list = [j]
                    best_delta = delta
                elseif delta == best_delta
                    push!(list, j)
                end
            end
            if list != []
                k = rand(list)
                move!(solution, i, k, instance)
            end
        end
        nb_non_improved += 1
        if phi < cost_PCC(solution, instance)
            nb_non_improved = 0
        end
    end
    return solution
end
