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
# Compute the weighted sum of a cost solution (an array)
function weighted_sum_PPC(cost_solution::Array{Int, 1})
    # TODO: this function can be dropped as soon as a sum_cost calculation is added in `fonction.jl`
    return sum(cost_solution[i] * WEIGHTS_OBJECTIVE_FUNCTION[i] for i in 1:3)
end

# Return a tuple of solution, first element is the cost,and the second one is the number of HRPC and LPRC violated.
function cost_VNS_LPRC(solution::Solution, instance::Instance)
    cost_solution = cost(solution, instance, 3)
    return weighted_sum_PCC(cost_solution)
end

# function that determine if left is better than right.
function is_better_PCC(left::Solution, right::Solution, instance::Instance)
    left_cost = cost(left, instance, 3)
    right_cost = cost(right, instance, 3)

    cost_better = weighted_sum_PCC(left_cost) < weighted_sum_PCC(right_cost)
    PCC_not_worse = left_cost[1] + left_cost[2] <= right_cost[1] + right_cost[2]

    return cost_better && PCC_not_worse
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

function localSearch_intensification_PCC_exchange!(solution::Solution, instance::Instance)
    # useful variable
    b0 = instance.nb_late_prec_day+1

    list = Array{Int, 1}()
    improved = true
    while improved
        improved = false
        critical_cars_set = critical_cars_PCC(solution, instance)
        for index_car_a in critical_cars_set
            best_delta = -1 # < 0 to avoid to select delta = 0 if there is no improvment (avoid cycle)
            empty!(list)
            for index_car_b in b0:solution.n
                if (index_car_a != index_car_b)
                    delta = weighted_sum_PCC( cost_move_exchange(solution, index_car_a, index_car_b, instance, 3) )
                    if delta < best_delta
                        list = [index_car_b]
                        best_delta = delta
                    elseif delta == best_delta
                        push!(list, index_car_b)
                    end
                end
            end
            if !isempty(list)
                index_car_b = rand(list)
                move_exchange!(solution, index_car_a, index_car_b, instance)
                improved = true
            end
        end
    end
    return solution
end


#=
function localSearch_intensification_PPC_insertion!(solution::Solution, instance::Instance)
    # useful variable
    b0 = instance.nb_late_prec_day+1

    improved = true
    while improved
        improved = false
        critical_cars_set = critical_cars_VNS_LPRC(solution, instance)
        for index_car in critical_cars_set
            best_delta = -1 # < 0 to avoid to select delta = 0 if there is no improvment (avoid cycle)
            matrix_deltas = cost_move_insertion(solution, index_car, instance, 3)
            array_deltas = [ (weighted_sum_VNS_LPRC(matrix_deltas[i, :]), i) for i in b0:solution.n]
            min = findmin(array_deltas)[1][1]
            if min < 0 && false
                list = map( x -> x[2], filter(x -> x[1] == min, array_deltas) )
                if list != []
                    index_insert = rand(list)
                    move_insertion!(solution, index_car, index_insert, instance)
                    improved = true
                end
            end
        end
    end
    return solution
end
=#

# Apply two local search, first one with insertion move, and the second one with exchange move.
function intensification_PCC!(solution::Solution, instance::Instance)
    localSearch_intensification_PCC_insertion!(solution, instance)
    localSearch_intensification_PCC_exchange!(solution, instance)
    return solution
end
