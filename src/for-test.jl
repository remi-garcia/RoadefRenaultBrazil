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

    update_matrices!(solution, solution.n, instance)
    return solution
end





#IN MAIN - test something like :
# for i in instance.nb_late_prec_day:(solution.n-1)
#     for j in i:solution.n
#         c1 = cost_move_exchange(solution, i, j, instance, 3)
#         c2 = TEST_cost_move_exchange(solution, i, j, instance, 3)
#         if ((c1[1] != c2[1]) || (c1[2] != c2[2]))
#             println("FAIL : ", c1, " vs. ", c2, " \t\t - exchange between ", i, " and ", j)
#         end
#     end
# end


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

    #Update sequence
    # car = solution.sequence[old_index]
    # deleteat!(solution.sequence, old_index)
    # insert!(solution.sequence, new_index, car)

    #Update sequence (better complexity ?)
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

    # TODO: COMPLEXITY NON-OPTIMAL
    update_matrices!(solution, solution.n, instance)

    return solution
end



#IN MAIN - test something like :
# for i in instance.nb_late_prec_day:(solution.n-1)
#     for j in i:solution.n
#         c1 = cost_move_insertion(solution, i, j, instance, 3)
#         c2 = TEST_cost_move_insertion(solution, i, j, instance, 3)
#         if ((c1[1] != c2[1]) || (c1[2] != c2[2]))
#             println("FAIL : ", c1, " vs. ", c2, " \t\t - exchange between ", i, " and ", j)
#         end
#     end
# end

"""
    TEST_cost_move_insertion(solution::Solution, car_pos_a::Int,
                        instance::Instance, objective::Int)

Bad complexity version for function cost_move_insertion.
"""
function TEST_cost_move_insertion(solution::Solution, car_pos_a::Int,
                             instance::Instance, objective::Int)

    cost_on_objective = zeros(Int, solution.n, 3)

    for i in (instance.nb_late_prec_day+1):solution.n
        s = deepcopy(solution)
        s = TEST_move_insertion!(s, car_pos_a, i, instance)
        c = cost(s, instance, objective) - cost(solution, instance, objective)
        cost_on_objective[i, :] = c
    end

    return cost_on_objective
end
