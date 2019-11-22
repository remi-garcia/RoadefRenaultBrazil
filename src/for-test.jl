#-------------------------------------------------------------------------------
# File: for-test.jl
# Description: This file contains bad complexity functions relatives to moves.
# Date: November 4, 2019
# Author: Jonathan Fontaine, Killian Fretaud, Rémi Garcia,
#         Boualem Lamraoui, Benoît Le Badezet, Benoit Loger
#-------------------------------------------------------------------------------


"""
    TEST_move_exchange!(solution::Solution, car_pos_a::Int, car_pos_b::Int, instance::Instance)

Bad complexity version for function move_exchange.
"""
function TEST_move_exchange!(solution::Solution, car_pos_a::Int, car_pos_b::Int, instance::Instance)
    if car_pos_a > car_pos_b
        return TEST_move_exchange!(solution, car_pos_b, car_pos_a, instance)
    end
    if car_pos_a == car_pos_b
        return solution
    end
    solution.sequence[car_pos_a], solution.sequence[car_pos_b] = solution.sequence[car_pos_b], solution.sequence[car_pos_a]
    update_matrices!(solution, instance.nb_cars, instance)

    return solution
end

"""
    TEST_cost_move_exchange(solution::Solution, car_pos_a::Int, car_pos_b::Int,
                       instance::Instance, objective::Int)

Bad complexity version for function cost_move_exchange.
"""
function TEST_cost_move_exchange(solution::Solution, car_pos_a::Int, car_pos_b::Int,
                            instance::Instance, objective::Int)
    s = deepcopy(solution)
    s = TEST_move_exchange!(s, car_pos_a, car_pos_b, instance)

    return cost(s, instance, objective) - cost(solution, instance, objective)
end

"""
    TEST_move_insertion!(solution::Solution, old_index::Int, new_index::Int, instance::Instance)

Bad complexity version for function move_insertion.
"""
function TEST_move_insertion!(solution::Solution, old_index::Int, new_index::Int, instance::Instance)

    car_inserted = solution.sequence[old_index]
    if old_index < new_index
        for car_moved_pos in old_index:(new_index-1)
            solution.sequence[car_moved_pos] = solution.sequence[car_moved_pos+1]
        end
        solution.sequence[new_index] = car_inserted
    end
    if old_index > new_index
        for car_moved_pos in old_index:-1:(new_index+1)
            solution.sequence[car_moved_pos] = solution.sequence[car_moved_pos-1]
        end
        solution.sequence[new_index] = car_inserted
    end
    update_matrices!(solution, instance.nb_cars, instance)

    return solution
end

"""
    TEST_cost_move_insertion(solution::Solution, car_pos_a::Int,
                        instance::Instance, objective::Int)

Bad complexity version for function cost_move_insertion.
"""
function TEST_cost_move_insertion(solution::Solution, car_pos_a::Int,
                             instance::Instance, objective::Int)

    cost_on_objective = zeros(Int, instance.nb_cars, 3)
    for i in (instance.nb_late_prec_day+1):instance.nb_cars
        s = deepcopy(solution)
        s = TEST_move_insertion!(s, car_pos_a, i, instance)
        c = cost(s, instance, objective) - cost(solution, instance, objective)
        cost_on_objective[i, :] = c
    end

    return cost_on_objective
end
