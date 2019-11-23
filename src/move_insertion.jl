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
    update_matrices!(solution, instance.nb_cars, instance)

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

    cost_on_objective = zeros(Int, instance.nb_cars, 3)
    b0 = instance.nb_late_prec_day+1

    delta1_for_first = zeros(Int, instance.nb_cars)
    delta1_for_second = zeros(Int, instance.nb_cars)
    delta2_for_first = zeros(Int, instance.nb_cars)
    delta2_for_second = zeros(Int, instance.nb_cars)

        #---------------------------------------------------------- Initialization of M1

    sequence = copy(solution.sequence)
    deleteat!(sequence, position)
    M1 = copy(solution.M1)

    #violations_caused_on_X removing the car will cause a variation on number of violations
    if objectives[1]
        M1, violations_caused_on_first = update_lines_remove!(
            solution, instance, # instance
            M1, position, # calcul
            1, instance.nb_HPRC # lines modified
        )
    end

    if objectives[2]
        M1, violations_caused_on_second = update_lines_remove!(
            solution, instance, # instance
            M1, position, # calcul
            instance.nb_HPRC+1, instance.nb_HPRC+instance.nb_LPRC # lines modified
        )
    end

        #---------------------------------------------------------- Cost of insertion

    # Cost on HPRC
    if objectives[1]
        #What about insertion at b0 (first place available)
        delta2_for_first[b0] = compute_delta2_for_b0(
            solution, instance, # instance
            M1, sequence, position, # calcul
            1, instance.nb_HPRC # for options
        )
        delta1_for_first[b0] = compute_delta1(
            solution, instance, # instance
            M1, sequence, b0, position, # calcul
            1, instance.nb_HPRC # for options
        )

        # for all other valid positions
        for index in (b0+1):(instance.nb_cars)
            # Delta 1 is compute as for b0
            delta1_for_first[index] = compute_delta1(solution, instance,
                                                     M1, sequence, index, position,
                                                     1, instance.nb_HPRC)
        end
        for index in (b0+1):(instance.nb_cars)
            delta2_for_first = compute_delta2(solution, instance,
                                              M1, sequence, index, position,
                                              1, instance.nb_HPRC,
                                              delta2_for_first)
        end
        # The cost is variation of deletion + delta1 (new sequence) + delta2 (modified sequences)
        for i in b0:(instance.nb_cars)
            cost_on_objective[i, 1] = delta1_for_first[i] + delta2_for_first[i] + violations_caused_on_first
        end
    end

    # Cost on LPRC
    if objectives[2]
        delta2_for_second[b0] = compute_delta2_for_b0(
            solution, instance,
            M1, sequence, position,
            instance.nb_HPRC+1,
            instance.nb_HPRC+instance.nb_LPRC)
        delta1_for_second[b0] = compute_delta1(
            solution, instance,
            M1, sequence, b0, position,
            instance.nb_HPRC+1, instance.nb_HPRC+instance.nb_LPRC)
        for index in (b0+1):instance.nb_cars
            # Delta 1 is compute as for b0
            delta1_for_second[index] = compute_delta1(
                solution, instance,
                M1, sequence, index, position,
                instance.nb_HPRC+1, instance.nb_HPRC+instance.nb_LPRC)
        end
        for index in (b0+1):(instance.nb_cars)
            delta2_for_second = compute_delta2(
                solution, instance,
                M1, sequence, index, position,
                (instance.nb_HPRC+1), (instance.nb_HPRC+instance.nb_LPRC),
                delta2_for_second)
        end

        # The cost is variation of deletion + delta1 (new sequence) + delta2 (modified sequences)
        for i in b0:(instance.nb_cars)
            cost_on_objective[i, 2] = delta1_for_second[i] + delta2_for_second[i] + violations_caused_on_second
        end
    end

    # Cost on PCC
    if objectives[3]
        for index in b0:instance.nb_cars
            car = solution.sequence[position]

            # Due to deletion
            if position > 1
                if instance.color_code[car] != instance.color_code[solution.sequence[position-1]]
                    cost_on_objective[index, 3] -= 1
                end

                if position < instance.nb_cars
                    if instance.color_code[solution.sequence[position-1]] != instance.color_code[solution.sequence[position+1]]
                        cost_on_objective[index, 3] += 1
                    end
                end
            end
            if position < instance.nb_cars
                if instance.color_code[car] != instance.color_code[solution.sequence[position+1]]
                    cost_on_objective[index, 3] -= 1
                end
            end

            # Due to insertion
            if index > 1 && index < instance.nb_cars
                if instance.color_code[sequence[index-1]] != instance.color_code[sequence[index]]
                    cost_on_objective[index, 3] -= 1
                end
            end
            if index > 1
                if instance.color_code[sequence[index-1]] != instance.color_code[car]
                    cost_on_objective[index, 3] += 1
                end
            end
            if index < instance.nb_cars
                if instance.color_code[sequence[index]] != instance.color_code[car]
                    cost_on_objective[index, 3] += 1
                end
            end
        end
    end

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

    b0 = instance.nb_late_prec_day+1
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
            if new_index_reached <= instance.nb_cars #TODO: is it not < ? Don't think so
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

    b0 = instance.nb_late_prec_day+1
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
            if new_unreached_index <= instance.nb_cars-1 # must be a valid index
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
        if first_unreached_index <= (instance.nb_cars-1)
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
    if index == instance.nb_cars
        C_insert = solution.sequence[car_pos_a]
        for option in first_line:last_line
            sequence_unreaching_it = index - instance.RC_q[option]
            if sequence_unreaching_it > 0
                for i in sequence_unreaching_it+1:instance.nb_cars
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
            if sequence_unreaching_it > 0 && index < instance.nb_cars
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
            if new_modified_sequence > 0 && first_unreached_index <= (instance.nb_cars-1)
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
