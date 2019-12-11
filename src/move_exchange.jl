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
    if car_pos_b == car_pos_a
        return solution
    elseif car_pos_b < car_pos_a
        return move_exchange!(solution, car_pos_b, car_pos_a, instance)
    end

    # #DEBUG and TODO: Comment / uncomment for debbuging.
    # #                Test the quality of the given solution.
    # s1 = deepcopy(solution)
    #
    # update_matrices!(solution, instance)
    # if !(solution.colors === nothing)
    #     initialize_batches!(solution, instance)
    # end
    #
    # error1 = false
    # if !(solution.colors === nothing)
    #     for i in 1:solution.length
    #         bool_print = false
    #         if s1.colors[i].start != solution.colors[i].start
    #             #println("\tBad start batch (",i,") - ", s1.colors[i].start," and ",solution.colors[i].start)
    #             error1 = true
    #             bool_print= true
    #         end
    #         if s1.colors[i].width != solution.colors[i].width
    #             #println("\tBad width batch (",i,") - ", s1.colors[i].width," and ",solution.colors[i].width)
    #             error1 = true
    #             bool_print= true
    #         end
    #         if bool_print
    #             #println("\t", instance.color_code[i] ,"-", instance.color_code[car_pos_a]," and ",instance.color_code[car_pos_b])
    #         end
    #     end
    # end
    #
    # error2 = false
    # for o in 1:instance.nb_HPRC+instance.nb_LPRC
    #     for i in 1:solution.length
    #         if s1.M1[o,i] != solution.M1[o,i]
    #             error2 = true
    #         end
    #         if s1.M2[o,i] != solution.M2[o,i]
    #             error2 = true
    #         end
    #         if s1.M3[o,i] != solution.M3[o,i]
    #             error2 = true
    #         end
    #     end
    # end
    # if error1 || error2
    #     print("\t\t\tIn move_exchange for given sol ", car_pos_a, " and ", car_pos_b)
    #     if error1
    #         print(" --  Error batch")
    #     end
    #     if error2
    #         print(" -- Error matrices")
    #     end
    #     println()
    # end

    # #DEBUG and TODO: Comment / uncomment for debbuging.
    # #                Ensure the quality of the solution.
    # update_matrices!(solution, instance)
    # initialize_batches!(solution, instance)

    car_a = solution.sequence[car_pos_a]
    car_b = solution.sequence[car_pos_b]
    solution.sequence[car_pos_a], solution.sequence[car_pos_b] = solution.sequence[car_pos_b], solution.sequence[car_pos_a]

    # COLORS
    if !(solution.colors === nothing)
        b0 = instance.nb_late_prec_day+1
        if instance.color_code[car_a] != instance.color_code[car_b]
            # cars are neighbors
            if car_pos_a+1 == car_pos_b
                # modifications at car_pos_a
                if (car_pos_a-1 >= b0
                && instance.color_code[car_b] == instance.color_code[solution.sequence[car_pos_a-1]])
                    solution.colors[car_pos_a-1].width += 1
                    solution.colors[car_pos_a] = solution.colors[car_pos_a-1]
                else
                    solution.colors[car_pos_a].width -= 1
                    solution.colors[car_pos_a] = Batch(1, car_pos_a)
                end
                # modifications at car_pos_b
                if (car_pos_b+1 <= solution.length
                && instance.color_code[car_a] == instance.color_code[solution.sequence[car_pos_b+1]])
                    solution.colors[car_pos_b+1].width += 1
                    solution.colors[car_pos_b+1].start -= 1
                    solution.colors[car_pos_b] = solution.colors[car_pos_b+1]
                else
                    solution.colors[car_pos_b].width -= 1
                    solution.colors[car_pos_b].start += 1
                    solution.colors[car_pos_b] = Batch(1, car_pos_b)
                end
            else # cars are not neighbors
                # CAR_POS_A
                # if start at car_pos_a -> is last batch of b's color ?
                if solution.colors[car_pos_a].start == car_pos_a
                    solution.colors[car_pos_a].width -= 1
                    solution.colors[car_pos_a].start += 1
                    if (car_pos_a-1 >= b0
                    && instance.color_code[car_b] == instance.color_code[solution.sequence[car_pos_a-1]])
                        solution.colors[car_pos_a-1].width += 1
                        solution.colors[car_pos_a] = solution.colors[car_pos_a-1]
                    else
                        solution.colors[car_pos_a] = Batch(1, car_pos_a)
                    end
                    # if car_a was a batch of width 1 -> is next batch of b's color ?
                    if instance.color_code[car_b] == instance.color_code[solution.sequence[car_pos_a+1]]
                        solution.colors[car_pos_a+1].start = solution.colors[car_pos_a].start
                        solution.colors[car_pos_a+1].width += solution.colors[car_pos_a].width
                        for index in (solution.colors[car_pos_a].start):car_pos_a
                            solution.colors[index] = solution.colors[car_pos_a+1]
                        end

                    end
                # elseif end at car_pos_a -> is next batch of b's color ?
                elseif (solution.colors[car_pos_a].start+solution.colors[car_pos_a].width) == car_pos_a+1
                    solution.colors[car_pos_a].width -= 1
                    if instance.color_code[car_b] == instance.color_code[solution.sequence[car_pos_a+1]]
                        solution.colors[car_pos_a+1].width += 1
                        solution.colors[car_pos_a+1].start -= 1
                        solution.colors[car_pos_a] = solution.colors[car_pos_a+1]
                    else
                        solution.colors[car_pos_a] = Batch(1, car_pos_a)
                    end
                # else batch of car_a will be split into two
                else
                    width = car_pos_a - solution.colors[car_pos_a].start
                    start = solution.colors[car_pos_a].start
                    batch = Batch(width, start)
                    for index in start:(car_pos_a-1)
                        solution.colors[index] = batch
                    end
                    solution.colors[car_pos_a].start = car_pos_a + 1
                    solution.colors[car_pos_a].width -= (width + 1)
                    solution.colors[car_pos_a] = Batch(1, car_pos_a)
                end

                # CAR_POS_B
                # if start at car_pos_b -> is last batch of a's color ?
                if solution.colors[car_pos_b].start == car_pos_b
                    solution.colors[car_pos_b].width -= 1
                    solution.colors[car_pos_b].start += 1
                    if instance.color_code[car_a] == instance.color_code[solution.sequence[car_pos_b-1]]
                        solution.colors[car_pos_b-1].width += 1
                        solution.colors[car_pos_b] = solution.colors[car_pos_b-1]
                    else
                        solution.colors[car_pos_b] = Batch(1, car_pos_b)
                    end
                    # if car_b was a batch of width 1 -> is next batch of a's color ?
                    if (car_pos_b+1 <= solution.length
                    && instance.color_code[car_a] == instance.color_code[solution.sequence[car_pos_b+1]])
                        solution.colors[car_pos_b+1].start = solution.colors[car_pos_b].start
                        solution.colors[car_pos_b+1].width += solution.colors[car_pos_b].width
                        for index in (solution.colors[car_pos_b].start):car_pos_b
                            solution.colors[index] = solution.colors[car_pos_b+1]
                        end
                    end
                # elseif end at car_pos_b -> is next batch of a's color ?
                elseif (solution.colors[car_pos_b].start+solution.colors[car_pos_b].width) == car_pos_b+1
                    solution.colors[car_pos_b].width -= 1
                    if (car_pos_b+1 <= solution.length
                    && instance.color_code[car_a] == instance.color_code[solution.sequence[car_pos_b+1]])
                        solution.colors[car_pos_b+1].width += 1
                        solution.colors[car_pos_b+1].start -= 1
                        solution.colors[car_pos_b] = solution.colors[car_pos_b+1]
                    else
                        solution.colors[car_pos_b] = Batch(1, car_pos_b)
                    end
                # else batch of car_b will be split into two
                else
                    width = car_pos_b - solution.colors[car_pos_b].start
                    start = solution.colors[car_pos_b].start
                    batch = Batch(width, start)
                    for index in start:(car_pos_b-1)
                        solution.colors[index] = batch
                    end
                    solution.colors[car_pos_b].start = car_pos_b + 1
                    solution.colors[car_pos_b].width -= (width + 1)
                    solution.colors[car_pos_b] = Batch(1, car_pos_b)
                end
            end
        end
    end

    # OPTIONS
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

    # #DEBUG and TODO: Comment / uncomment for debbuging.
    # #                Test the quality of the move.
    # s1 = deepcopy(solution)
    #
    update_matrices!(solution, instance)
    if !(solution.colors === nothing)
        initialize_batches!(solution, instance)
    end
    #
    # error1 = false
    # for i in 1:solution.length
    #     bool_print = false
    #     if s1.colors[i].start != solution.colors[i].start
    #         println("\tBad start batch (",i,") - ", s1.colors[i].start," and ",solution.colors[i].start)
    #         error1 = true
    #         bool_print= true
    #     end
    #     if s1.colors[i].width != solution.colors[i].width
    #         println("\tBad width batch (",i,") - ", s1.colors[i].width," and ",solution.colors[i].width)
    #         error1 = true
    #         bool_print= true
    #     end
    #     if bool_print
    #         println("\t", instance.color_code[i] ,"-", instance.color_code[car_pos_a]," and ",instance.color_code[car_pos_b])
    #     end
    # end
    #
    # error2 = false
    # for o in 1:instance.nb_HPRC+instance.nb_LPRC
    #     for i in 1:solution.length
    #         if s1.M1[o,i] != solution.M1[o,i]
    #             error2 = true
    #         end
    #         if s1.M2[o,i] != solution.M2[o,i]
    #             error2 = true
    #         end
    #         if s1.M3[o,i] != solution.M3[o,i]
    #             error2 = true
    #         end
    #     end
    # end
    # if error1 || error2
    #     println("\nIn move_exchange for ", car_pos_a, " and ", car_pos_b)
    #     if error1
    #         println("\nError batch")
    #     end
    #     if error2
    #         println("\nError matrices")
    #     end
    # end

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

    # # DEBUG and TODO: Comment / uncomment for debbuging.
    # #                 Ensure to test every variation.
    # objectives = trues(3)

    if car_pos_b == car_pos_a
        return zeros(Int, 3)
    elseif car_pos_b < car_pos_a
        return cost_move_exchange(solution, car_pos_b, car_pos_a, instance, objectives)
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
        b0 = instance.nb_late_prec_day+1
        car_a = solution.sequence[car_pos_a]
        car_b = solution.sequence[car_pos_b]
        if instance.color_code[car_a] != instance.color_code[car_b]
            # First position
            if car_pos_a > b0
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

    # #DEBUG and TODO: Comment / uncomment for debbuging.
    # #                Test the quality of the variation computed.
    # s1 = deepcopy(solution)
    # s1.sequence[car_pos_a], s1.sequence[car_pos_b] = s1.sequence[car_pos_b], s1.sequence[car_pos_a]
    # update_matrices!(s1, instance)
    #
    # real_cost = cost(s1, instance, objectives) - cost(solution, instance, objectives)
    # if real_cost != cost_on_objective
    #     println("\nIn cost_move_exchange for ", car_pos_a, " and ", car_pos_b)
    #     println("\tError (real vs computed) : ", real_cost, " - ", cost_on_objective)
    # end

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
