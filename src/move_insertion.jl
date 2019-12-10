#-------------------------------------------------------------------------------
# File: move_insertion.jl
# Description: This file contains all functions relatives to the insertion move.
# Date: November 4, 2019
# Author: Jonathan Fontaine, Killian Fretaud, Rémi Garcia,
#         Boualem Lamraoui, Benoît Le Badezet, Benoit Loger
#-------------------------------------------------------------------------------


"""
    move_insertion!(solution::Solution, old_index::Int,
                    new_index::Int, instance::Instance)
Replaces car at `old_index` at `new_index` and updates the solution's matrices.
"""
function move_insertion!(solution::Solution, old_index::Int,
                         new_index::Int, instance::Instance)

    # #DEBUG and TODO: Comment / uncomment for debbuging.
    # #                Ensure the quality of the solution.
    # update_matrices!(solution, instance)
    # initialize_batches!(solution, instance)

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
    # for o in 1:nb_RC(instance)
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
    #     print("\t\t\tIn move_insertion for given sol ", old_index, " at ", new_index)
    #     if error1
    #         print(" --  Error batch")
    #     end
    #     if error2
    #         print(" -- Error matrices")
    #     end
    #     println()
    # end

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
    update_matrices!(solution, instance)
    if !(solution.colors === nothing)
        initialize_batches!(solution, instance)
    end

    # #DEBUG and TODO: Comment / uncomment for debbuging.
    # #                Test the quality of the move.
    # s1 = deepcopy(solution)
    #
    # update_matrices!(solution, instance)
    # if !(solution.colors === nothing)
    #     initialize_batches!(solution, instance)
    # end
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
    #         println("\t", instance.color_code[i] ,"-", instance.color_code[old_index]," to ",instance.color_code[new_index])
    #     end
    # end
    #
    # error2 = false
    # for o in 1:nb_RC(instance)
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
    #     println("\nIn move_insertion for ", old_index, " to ", new_index)
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
    cost_move_insertion(solution::Solution, car_pos_a::Int,
                        instance::Instance, objectives::BitArray{1})
Returns the cost of the insertion of the car `car_pos_a` for all valid positions
with respect to objectives `objectives`. A negative cost means that
the move is interesting with respect to treated objectives.
"""
function cost_move_insertion(solution::Solution, position::Int,
                             instance::Instance, objectives::BitArray{1})
    @assert length(objectives) == 3

    # # DEBUG and TODO: Comment / uncomment for debbuging.
    # #                 Ensure to test every variation.
    # objectives = trues(3)

    cost_on_objective = zeros(Int, solution.length, 3)
    b0 = get_b0(instance)

    delta1_for_first = zeros(Int, solution.length)
    delta1_for_second = zeros(Int, solution.length)
    delta2_for_first = zeros(Int, solution.length)
    delta2_for_second = zeros(Int, solution.length)

        #---------------------------------------------------------- Initialization of M1

    sequence = copy(solution.sequence)
    deleteat!(sequence, position)
    M1 = copy(solution.M1)

    #violations_caused_on_X removing the car will cause a variation on number of violations
    if objectives[1]
        M1, violations_caused_on_first = update_lines_remove!(
            solution, instance, # instance
            M1, position, # calcul
            1, nb_HPRC(instance) # lines modified
        )
    end

    if objectives[2]
        M1, violations_caused_on_second = update_lines_remove!(
            solution, instance, # instance
            M1, position, # calcul
            nb_HPRC(instance)+1, nb_RC(instance) # lines modified
        )
    end

        #---------------------------------------------------------- Cost of insertion

    # Cost on HPRC
    if objectives[1]
        #What about insertion at b0 (first place available)
        delta2_for_first[b0] = compute_delta2_for_b0(
            solution, instance, # instance
            M1, sequence, position, # calcul
            1, nb_HPRC(instance) # for options
        )
        delta1_for_first[b0] = compute_delta1(
            solution, instance, # instance
            M1, sequence, b0, position, # calcul
            1, nb_HPRC(instance) # for options
        )

        # for all other valid positions
        for index in (b0+1):solution.length
            # Delta 1 is compute as for b0
            delta1_for_first[index] = compute_delta1(solution, instance,
                                                     M1, sequence, index, position,
                                                     1, nb_HPRC(instance))
        end
        for index in (b0+1):solution.length
            delta2_for_first = compute_delta2(solution, instance,
                                              M1, sequence, index, position,
                                              1, nb_HPRC(instance),
                                              delta2_for_first)
        end
        # The cost is variation of deletion + delta1 (new sequence) + delta2 (modified sequences)
        for i in b0:solution.length
            cost_on_objective[i, 1] = delta1_for_first[i] + delta2_for_first[i] + violations_caused_on_first
        end
    end

    # Cost on LPRC
    if objectives[2]
        delta2_for_second[b0] = compute_delta2_for_b0(
            solution, instance,
            M1, sequence, position,
            nb_HPRC(instance)+1,
            nb_RC(instance))
        delta1_for_second[b0] = compute_delta1(
            solution, instance,
            M1, sequence, b0, position,
            nb_HPRC(instance)+1, nb_RC(instance))
        for index in (b0+1):solution.length
            # Delta 1 is compute as for b0
            delta1_for_second[index] = compute_delta1(
                solution, instance,
                M1, sequence, index, position,
                nb_HPRC(instance)+1, nb_RC(instance))
        end
        for index in (b0+1):solution.length
            delta2_for_second = compute_delta2(
                solution, instance,
                M1, sequence, index, position,
                (nb_HPRC(instance)+1), (nb_RC(instance)),
                delta2_for_second)
        end

        # The cost is variation of deletion + delta1 (new sequence) + delta2 (modified sequences)
        for i in b0:solution.length
            cost_on_objective[i, 2] = delta1_for_second[i] + delta2_for_second[i] + violations_caused_on_second
        end
    end

    # Cost on PCC
    if objectives[3]
        for index in b0:solution.length
            car = solution.sequence[position]

            # Due to deletion
            if position > 1
                if instance.color_code[car] != instance.color_code[solution.sequence[position-1]]
                    cost_on_objective[index, 3] -= 1
                end

                if position < solution.length
                    if instance.color_code[solution.sequence[position-1]] != instance.color_code[solution.sequence[position+1]]
                        cost_on_objective[index, 3] += 1
                    end
                end
            end
            if position < solution.length
                if instance.color_code[car] != instance.color_code[solution.sequence[position+1]]
                    cost_on_objective[index, 3] -= 1
                end
            end

            # Due to insertion
            if index > 1 && index < solution.length
                if instance.color_code[sequence[index-1]] != instance.color_code[sequence[index]]
                    cost_on_objective[index, 3] -= 1
                end
            end
            if index > 1
                if instance.color_code[sequence[index-1]] != instance.color_code[car]
                    cost_on_objective[index, 3] += 1
                end
            end
            if index < solution.length
                if instance.color_code[sequence[index]] != instance.color_code[car]
                    cost_on_objective[index, 3] += 1
                end
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
    cost_move_insertion(solution::Solution, car_pos_a::Int,
                        instance::Instance, objective::Int)
Returns the cost of the insertion of the car `car_pos_a` for all valid positions
with respect to objectives 1 to `objective`. A negative cost means that the move
is interesting with respect to treated objective.
"""
cost_move_insertion(solution::Solution, position::Int, instance::Instance, objective::Int) =
    cost_move_insertion(solution, position, instance, [trues(objective) ; falses(3-objective)])


        #-------------------------------------------------------#
        #                                                       #
        #                   Factorization                       #
        #         #TODO: Need refactoring and checking          #
        #-------------------------------------------------------#


"""
    update_lines_remove!(solution::Solution, instance::Instance,
                         M1::Array{Int,2}, car_pos_a::Int,
                         first_line::Int, last_line::Int)
For factorization
"""
function update_lines_remove!(solution::Solution, instance::Instance,
                              M1::Array{Int,2}, car_pos_a::Int,
                              first_line::Int, last_line::Int)

    violations_caused = 0 # Removing car_pos_a will change the number of violations.
    due_to_sequence_removed = 0

    b0 = get_b0(instance)
    # forall option there is 1 to last_sequence_intact sequences unchanged
    for option in first_line:last_line
        last_sequence_intact = car_pos_a - instance.RC_q[option]
        if last_sequence_intact < 0
            last_sequence_intact = 0
        end
        # for car in 1:last_sequence_intact : do nothing

        # forall sequences from last_sequence_intact+1 to pos_a-1,
        for index in (last_sequence_intact+1):(car_pos_a-1)
            # one less violation if car has the option
            if instance.RC_flag[solution.sequence[car_pos_a], option]
                if M1[option, index] > instance.RC_p[option] #
                    violations_caused -= 1
                end
                M1[option, index] -= 1
            end
            # one more violation if new car reached has the option
            new_index_reached = index + instance.RC_q[option]
            if new_index_reached <= solution.length #TODO: is it not < ? Don't think so
                if instance.RC_flag[solution.sequence[new_index_reached], option]
                    if M1[option, index] >= instance.RC_p[option]
                        violations_caused += 1
                    end
                    M1[option, index] += 1
                end
            end
        end

        # sequence pos_a is deleted, every violation of this sequence disappear
        violations_caused -= max(0, solution.M1[option, car_pos_a] - instance.RC_p[option])

        if (car_pos_a == b0)
            due_to_sequence_removed -= (max(0, solution.M1[option, car_pos_a] - instance.RC_p[option]))
        end

        # forall sequences from pos_a+1 to n are intact but shifted,
        for index in (car_pos_a):(instance.nb_cars-1)
            M1[option, index] = M1[option, index+1]
        end

        M1[option, instance.nb_cars] = 0 # There is no car here
    end

    return M1, violations_caused
end


"""
    compute_delta2_for_b0(solution::Solution, instance::Instance,
                          M1::Array{Int,2}, sequence::Array{Int,1},
                          car_pos_a::Int, first_line::Int, last_line::Int)
For factorization
"""
function compute_delta2_for_b0(solution::Solution, instance::Instance,
                               M1::Array{Int,2}, sequence::Array{Int,1},
                               car_pos_a::Int, first_line::Int, last_line::Int)

    b0 = get_b0(instance)
    delta2 = 0

    C_in = solution.sequence[car_pos_a]

    for option in first_line:last_line

        #there is q(oj)-1 modified sequences...
        first_modified_sequence = (b0 - instance.RC_q[option]) + 1
        if first_modified_sequence < 1 # must be a valid index
            first_modified_sequence = 1
        end

        for modified_sequence in first_modified_sequence:(b0-1)
            new_unreached_index = modified_sequence + instance.RC_q[option] - 1

            # car force another one to quit the sequence
            if new_unreached_index <= solution.length-1 # must be a valid index
                C_out = sequence[new_unreached_index]
                # C_in has different option than C_out -> variation in violations number
                if xor(instance.RC_flag[C_in, option], instance.RC_flag[C_out, option])
                    if instance.RC_flag[C_out, option] && M1[option, modified_sequence] > instance.RC_p[option]
                        delta2 -= 1
                    end
                    if instance.RC_flag[C_in, option] && M1[option, modified_sequence] >= instance.RC_p[option]
                        delta2 += 1
                    end
                end
            else # it is an ending sequence, there is no new unreached car
                if instance.RC_flag[C_in, option] && M1[option, modified_sequence] >= instance.RC_p[option]
                    delta2 += 1
                end
            end
        end
    end

    return delta2
end


"""
    compute_delta1(solution::Solution, instance::Instance,
                   M1::Array{Int,2}, sequence::Array{Int,1}, cursor::Int,
                   car_pos_a::Int, first_line::Int, last_line::Int)
For factorization
"""
function compute_delta1(solution::Solution, instance::Instance,
                        M1::Array{Int,2}, sequence::Array{Int,1}, cursor::Int,
                        car_pos_a::Int, first_line::Int, last_line::Int)

    delta1 = 0
    for option in first_line:last_line
        # ... and one new sequence at cursor
        # This is basically sequence at cursor without the (cursor + instance.RC_q[option] - 1)-th index (ejected by car)
        first_unreached_index = cursor + instance.RC_q[option] - 1
        # has different option than unreached -> variation in violations number
        # car is in ...
        variation = 0
        if instance.RC_flag[solution.sequence[car_pos_a], option]
            variation += 1
        end
        # ... and first_unreached_index (if it exists) is not
        if first_unreached_index <= (solution.length-1)
            if instance.RC_flag[sequence[first_unreached_index], option]
                variation -= 1
            end
        end
        delta1 += max(0, (M1[option, cursor] + variation) - instance.RC_p[option])
    end

    return delta1
end



"""
    compute_delta2(solution::Solution, instance::Instance,
                   M1::Array{Int,2}, sequence::Array{Int,1}, index::Int,
                   car_pos_a::Int, first_line::Int, last_line::Int,
                   delta2_for_objective)
For factorization
"""
function compute_delta2(solution::Solution, instance::Instance,
                        M1::Array{Int,2}, sequence::Array{Int,1}, index::Int,
                        car_pos_a::Int, first_line::Int, last_line::Int,
                        delta2_for_objective)
    #TODO: How to handle this case?
    if index == solution.length
        C_insert = solution.sequence[car_pos_a]
        for option in first_line:last_line
            sequence_unreaching_it = index - instance.RC_q[option]
            if sequence_unreaching_it > 0
                for i in (sequence_unreaching_it+1):solution.length
                    if (M1[option, i] >= instance.RC_p[option] && instance.RC_flag[C_insert, option])
                        delta2_for_objective[index] += 1
                    end
                end
            end
        end
    else
        delta2_for_objective[index] = delta2_for_objective[index-1]

        C_insert = solution.sequence[car_pos_a] # the car we want to insert

        for option in first_line:last_line
            # What is called in the article: delta_{b-q(o_j)}
            # there is one sequence too far from us now
            sequence_unreaching_it = index - instance.RC_q[option]
            if sequence_unreaching_it > 0 && index < solution.length
                C_in = sequence[index-1] # It was previously push out (shifted to index in the last calcul of d2)
                if xor(instance.RC_flag[C_insert, option], instance.RC_flag[C_in, option])
                    # The last sequence is now more violated than before ?
                    if instance.RC_flag[C_in, option]
                        if M1[option, sequence_unreaching_it] > instance.RC_p[option]
                            delta2_for_objective[index] += 1
                        end
                    end
                    # Car was counted as a violation
                    if instance.RC_flag[C_insert, option]
                        if M1[option, sequence_unreaching_it] >= instance.RC_p[option]
                            delta2_for_objective[index] -= 1
                        end
                    end
                end
            end

            # What is called in the article: delta_{b-1}
            new_modified_sequence = index - 1
            first_unreached_index = index + instance.RC_q[option] - 2
            if new_modified_sequence > 0 && first_unreached_index <= (solution.length-1)
                C_out = sequence[first_unreached_index]
                if xor(instance.RC_flag[C_out, option], instance.RC_flag[C_insert, option])
                    # The new sequence is now more violated than before
                    if instance.RC_flag[C_out, option]
                        if M1[option, new_modified_sequence] > instance.RC_p[option]
                            delta2_for_objective[index] -= 1
                        end
                    end
                    # Car dropped one violation
                    if instance.RC_flag[C_insert, option]
                        if M1[option, new_modified_sequence] >= instance.RC_p[option]
                            delta2_for_objective[index] += 1
                        end
                    end
                end
            else # sequence was at the end, no-one is getting out
                # Car may cause one violation
                if instance.RC_flag[C_insert, option]
                    if M1[option, new_modified_sequence] >= instance.RC_p[option]
                        delta2_for_objective[index] += 1
                    end
                end
            end
        end
    end

    return delta2_for_objective
end
