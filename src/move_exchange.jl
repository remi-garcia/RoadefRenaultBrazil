#-------------------------------------------------------------------------------
# File: move_exchange.jl
# Description: This file contains all functions relatives to the echange move.
# Date: November 4, 2019
# Author: Jonathan Fontaine, Killian Fretaud, Rémi Garcia,
#         Boualem Lamraoui, Benoît Le Badezet, Benoit Loger
#-------------------------------------------------------------------------------


#TODO: Need refactoring

"""
    move_exchange!(solution::Solution, car_pos_a::Int,
                   car_pos_b::Int, instance::Instance)

Interverts the car `car_pos_a` with the car `car_pos_b` in `solution.sequence`. Updates
`solution.M1`, `solution.M2` and `solution.M3`.
"""
function move_exchange!(solution::Solution, car_pos_a::Int,
                        car_pos_b::Int, instance::Instance)
    if car_pos_b < car_pos_a
        return move_exchange!(solution, car_pos_b, car_pos_a, instance)
    elseif car_pos_b == car_pos_a
        return solution
    end

    car_a = solution.sequence[car_pos_a]
    car_b = solution.sequence[car_pos_b]
    solution.sequence[car_pos_a], solution.sequence[car_pos_b] = solution.sequence[car_pos_b], solution.sequence[car_pos_a]

    for option in 1:(instance.nb_HPRC + instance.nb_LPRC)
        if xor(instance.RC_flag[car_a, option], instance.RC_flag[car_b, option])
            first_modified_pos_a = car_pos_a - instance.RC_q[option] + 1
            last_modified_sequence_a = min(car_pos_a, car_pos_b - instance.RC_q[option])
            first_modified_sequence_b = max(car_pos_a+1, car_pos_b - instance.RC_q[option]+1)

            plus_minus_one = 1
            if instance.RC_flag[car_a, option]
                plus_minus_one = -1
            end

            if first_modified_pos_a < 1
                first_modified_pos_a = 1
            end

            deltaM2 = 0
            deltaM3 = 0
            if last_modified_sequence_a > 0
                deltaM2 = solution.M2[option, last_modified_sequence_a]
                deltaM3 = solution.M3[option, last_modified_sequence_a]

                for car_pos in first_modified_pos_a:last_modified_sequence_a
                    solution.M1[option, car_pos] += plus_minus_one
                    if car_pos == 1
                        solution.M2[option, car_pos] = 0
                        solution.M3[option, car_pos] = 0
                    else
                        solution.M2[option, car_pos] = solution.M2[option, car_pos-1]
                        solution.M3[option, car_pos] = solution.M3[option, car_pos-1]
                    end
                    # M3 is >=
                    if solution.M1[option, car_pos] >= instance.RC_p[option]
                        solution.M3[option, car_pos] += 1
                        # M2 is >
                        if solution.M1[option, car_pos] > instance.RC_p[option]
                            solution.M2[option, car_pos] += 1
                        end
                    end
                end

                deltaM2 = solution.M2[option, last_modified_sequence_a] - deltaM2
                deltaM3 = solution.M3[option, last_modified_sequence_a] - deltaM3

                for car_pos in (last_modified_sequence_a+1):(first_modified_sequence_b-1)
                    solution.M2[option, car_pos] += deltaM2
                    solution.M3[option, car_pos] += deltaM3
                end
            end

            deltaM2 = solution.M2[option, car_pos_b]
            deltaM3 = solution.M3[option, car_pos_b]

            for car_pos in first_modified_sequence_b:car_pos_b
                solution.M1[option, car_pos] -= plus_minus_one
                #TODO: maybe I should not have remove the ``if( == 1)``
                solution.M2[option, car_pos] = solution.M2[option, car_pos-1]
                solution.M3[option, car_pos] = solution.M3[option, car_pos-1]
                # M3 is >=
                if solution.M1[option, car_pos] >= instance.RC_p[option]
                    solution.M3[option, car_pos] += 1
                    # M2 is >
                    if solution.M1[option, car_pos] > instance.RC_p[option]
                        solution.M2[option, car_pos] += 1
                    end
                end
            end

            deltaM2 = solution.M2[option, car_pos_b] - deltaM2
            deltaM3 = solution.M3[option, car_pos_b] - deltaM3

            for car_pos in (car_pos_b+1):solution.length
                solution.M2[option, car_pos] += deltaM2
                solution.M3[option, car_pos] += deltaM3
            end
        end
    end

    return solution
end

"""
    cost_move_exchange(solution::Solution, car_pos_a::Int, car_pos_b::Int,
                       instance::Instance, objectives::BitArray{1})

Returns the cost of the exchange of the car `car_pos_a` with the car `car_pos_b` with
respect to objective `objectives`. A negative cost means that the move is interesting
with respect to objective `objectives`.
"""
function cost_move_exchange(solution::Solution, car_pos_a::Int, car_pos_b::Int,
                            instance::Instance, objectives::BitArray{1})
    @assert length(objectives) == 3

    if car_pos_b < car_pos_a
        return cost_move_exchange(solution, car_pos_b, car_pos_a, instance, objectives)
    elseif car_pos_b == car_pos_a
        return zeros(Int, 3)
    end

    cost_on_objective = zeros(Int, 3)

    if objectives[1] # Cost on HPRC
        cost_on_objective[1] = compute_delta_exchange(solution, instance,
                                                      car_pos_a, car_pos_b,
                                                      1, instance.nb_HPRC)
    end

    if objectives[2] # Cost on LPRC
        cost_on_objective[2] = compute_delta_exchange(solution, instance,
                                                      car_pos_a, car_pos_b,
                                                      instance.nb_HPRC+1,
                                                      instance.nb_HPRC+instance.nb_LPRC)
    end

    if objectives[3] # Cost on PCC
        car_a = solution.sequence[car_pos_a]
        car_b = solution.sequence[car_pos_b]
        if instance.color_code[car_a] != instance.color_code[car_b]
            # First position
            if car_pos_a > 1
                if instance.color_code[car_a] != instance.color_code[solution.sequence[car_pos_a-1]]
                    cost_on_objective[3] -= 1
                end
                if instance.color_code[car_b] != instance.color_code[solution.sequence[car_pos_a-1]]
                    cost_on_objective[3] += 1
                end
            end
            if instance.color_code[car_a] != instance.color_code[solution.sequence[car_pos_a+1]]
                cost_on_objective[3] -= 1
            end
            if instance.color_code[car_b] != instance.color_code[solution.sequence[car_pos_a+1]]
                cost_on_objective[3] += 1
            end
            # Second position
            if instance.color_code[car_b] != instance.color_code[solution.sequence[car_pos_b-1]]
                cost_on_objective[3] -= 1
            end
            if instance.color_code[car_a] != instance.color_code[solution.sequence[car_pos_b-1]]
                cost_on_objective[3] += 1
            end
            if car_pos_b < solution.length
                if instance.color_code[car_b] != instance.color_code[solution.sequence[car_pos_b+1]]
                    cost_on_objective[3] -= 1
                end
                if instance.color_code[car_a] != instance.color_code[solution.sequence[car_pos_b+1]]
                    cost_on_objective[3] += 1
                end
            end

            if (car_pos_a+1) == car_pos_b
                cost_on_objective[3] += 2
            end
        end
    end

    return cost_on_objective
end

"""
    cost_move_exchange(solution::Solution, car_pos_a::Int, car_pos_b::Int,
                       instance::Instance, objective::Int)

Returns the cost of the exchange of the car `car_pos_a` with the car `car_pos_b` with
respect to objectives 1 to `objective`. A negative cost means that the move is
interesting with respect to objective 1 to `objective`.
"""
cost_move_exchange(solution::Solution, car_pos_a::Int, car_pos_b::Int, instance::Instance, objective::Int) =
    cost_move_exchange(solution, car_pos_a, car_pos_b, instance, [trues(objective) ; falses(3-objective)])


            #-------------------------------------------------------#
            #                                                       #
            #                   Factorization                       #
            #                                                       #
            #-------------------------------------------------------#

"""
    compute_delta_exchange(solution::Solution, instance::Instance,
                           car_pos_a::Int, car_pos_b::Int,
                           first_line::Int, last_line::Int)

For factorization
"""
function compute_delta_exchange(solution::Solution, instance::Instance,
                                car_pos_a::Int, car_pos_b::Int,
                                first_line::Int, last_line::Int)
    variation = 0
    car_a = solution.sequence[car_pos_a]
    car_b = solution.sequence[car_pos_b]
    for option in first_line:last_line
        # No cost if both have it / have it not
        if xor(instance.RC_flag[car_a, option], instance.RC_flag[car_b, option])
            last_ended_sequence_a = car_pos_a - instance.RC_q[option]
            first_modified_sequence_a = min(car_pos_a, car_pos_b - instance.RC_q[option])
            last_unmodified_sequence_b = max(car_pos_a, car_pos_b - instance.RC_q[option])

            if instance.RC_flag[car_a, option]
                if first_modified_sequence_a > 0
                    if last_ended_sequence_a > 0
                        variation -= solution.M2[option, first_modified_sequence_a] - solution.M2[option, last_ended_sequence_a]
                    else
                        variation -= solution.M2[option, first_modified_sequence_a]
                    end
                end
                if last_unmodified_sequence_b > 0
                    variation += solution.M3[option, car_pos_b] - solution.M3[option, last_unmodified_sequence_b]
                else
                    variation += solution.M3[option, car_pos_b]
                end
            else
                if first_modified_sequence_a > 0
                    if last_ended_sequence_a > 0
                        variation += solution.M3[option, first_modified_sequence_a] - solution.M3[option, last_ended_sequence_a]
                    else
                        variation += solution.M3[option, first_modified_sequence_a]
                    end
                end
                if last_unmodified_sequence_b > 0
                    variation -= solution.M2[option, car_pos_b] - solution.M2[option, last_unmodified_sequence_b]
                else
                    variation -= solution.M2[option, car_pos_b]
                end
            end
        end
    end
    return variation
end
