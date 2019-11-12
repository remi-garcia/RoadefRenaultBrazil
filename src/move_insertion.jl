#-------------------------------------------------------------------------------
# File: move_insertion.jl
# Description: This file contains all functions relatives to the insertion move.
# Date: November 4, 2019
# Author: Jonathan Fontaine, Killian Fretaud, Rémi Garcia,
#         Boualem Lamraoui, Benoît Le Badezet, Benoit Loger
#-------------------------------------------------------------------------------


"""
    move_insertion!(solution::Solution, old_index::Int, new_index::Int, instance::Instance)

Replaces car at `old_index` at `new_index` and updates the solution's matrices.
"""
function move_insertion!(solution::Solution, old_index::Int, new_index::Int, instance::Instance)

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
                        instance::Instance, objective::Int)

Return the cost of the insertion of the car `car_pos_a` before the car `car_pos_b` with respect
to objective `objective`. A negative cost means that the move is interesting
with respect to objective `objective`.
CAREFUL: Return an array of delta!
"""
function cost_move_insertion(solution::Solution, position::Int,
                             instance::Instance, objective::Int)
    #TODO it might be important that objective is a vector of Int, then we could
    #return a vector of cost.

    # objective should take values between 1 and 3.
    @assert objective >= 1
    @assert objective <= 3

    cost_on_objective = zeros(Int, instance.nb_cars, 3)
    b0 = instance.nb_late_prec_day+1

    delta1_for_First = zeros(Int,instance.nb_cars) ; delta1_for_Second = zeros(Int,instance.nb_cars)
    delta2_for_First = zeros(Int,instance.nb_cars) ; delta2_for_Second = zeros(Int,instance.nb_cars)

        #---------------------------------------------------------- Initialization of M1

    sequence = copy(solution.sequence)
    deleteat!(sequence, position)
    push!(sequence, solution.sequence[position])
    M1 = copy(solution.M1)
    #car = solution.sequence[position]

    #violations_caused_on_X removing the car will cause a variation on number of violations
    println("update first")
    # objective >= 1 #Must improve or keep HPRC
    M1, violations_caused_on_First = update_lines_remove!(
        solution, instance, # instance
        M1, position, # calcul
        1, instance.nb_HPRC # lines modified
    )
    println(violations_caused_on_First)

    if objective >= 2 #Must improve or keep HPRC
        println("update second")
        M1, violations_caused_on_Second = update_lines_remove!(
            solution, instance, # instance
            M1, position, # calcul
            instance.nb_HPRC+1, instance.nb_HPRC+instance.nb_LPRC # lines modified
        )
        println(violations_caused_on_Second)
    end

        #---------------------------------------------------------- Cost of insertion

    # objective >= 1 #Must improve or keep HPRC

    #What about insertion at b0 (first place available)
    println("d2 at b0")
    delta2_for_First[b0] = compute_delta2_for_b0(
        solution, instance, # instance
        M1, sequence, position, # calcul
        1, instance.nb_HPRC # for options
    )
    println("d1 at b0")
    delta1_for_First[b0] = compute_delta1(
        solution, instance, # instance
        M1, sequence, b0, position, # calcul
        1, instance.nb_HPRC # for options
    )

    # for all other valid positions
    for index in (b0+1):(instance.nb_cars)
        # Delta 1 is compute as for b0
        delta1_for_First[index] = compute_delta1(
            solution, instance, # instance
            M1, sequence, index, position, # calcul
            1, instance.nb_HPRC # for options
        )
    end
    for index in (b0+1):(instance.nb_cars)
        delta2_for_First = compute_delta2(
            solution, instance, # instance
            M1, sequence, index, position, # calcul
            1, instance.nb_HPRC, # lines modified
            delta2_for_First
        )
    end

    # Same for seconde objective
    if objective >= 2
        println("d2 at b0 (2nd)")
        delta2_for_Second[b0] = compute_delta2_for_b0(
            solution, instance, # instance
            M1, sequence, position, # calcul
            instance.nb_HPRC+1, instance.nb_HPRC+instance.nb_LPRC  # for options
        )
        println("d1 at b0 (2nd)")
        delta1_for_Second[b0] = compute_delta1(
            solution, instance, # instance
            M1, sequence, b0, position, # calcul
            instance.nb_HPRC+1, instance.nb_HPRC+instance.nb_LPRC  # for options
        )

        for index in (b0+1):instance.nb_cars
            # Delta 1 is compute as for b0
            delta1_for_Second[index] = compute_delta1(
                solution, instance, # instance
                M1, sequence, index, position, # calcul
                instance.nb_HPRC+1, instance.nb_HPRC+instance.nb_LPRC # for options
            )
        end
        for index in (b0+1):(instance.nb_cars)
            delta2_for_Second = compute_delta2(
                solution, instance, # instance
                M1, sequence, index, position, # calcul
                (instance.nb_HPRC+1), (instance.nb_HPRC+instance.nb_LPRC), # lines modified
                delta2_for_Second
            )
        end
    end

    # The cost is variation of deletion + delta1 (new sequence) + delta2 (modified sequences)
    for i in b0:(instance.nb_cars)
        cost_on_objective[i, 1] = delta1_for_First[i] + delta2_for_First[i] + violations_caused_on_First
        if objective >= 2
            cost_on_objective[i, 2] = delta1_for_Second[i] + delta2_for_Second[i] + violations_caused_on_Second
        end
    end

    # Cost on obective PCC
    if objective >= 3
        #TODO
    end

    return cost_on_objective
end


        #-------------------------------------------------------#
        #                                                       #
        #                   Factorization                       #
        #         #TODO: Need refactoring and checking          #
        #-------------------------------------------------------#


"""
        update_lines_cost_move_insert!(
                        solution::Solution, instance::Instance, # instance
                        M1::Array{Int,2}, n::Int, car_pos_a::Int, cost_on_objective::Array{Int,2}, # calcul
                        first_line::Int, last_line::Int # lines modified
                    )

For factorization
"""
function update_lines_remove!(
                        solution::Solution, instance::Instance, # instance
                        M1::Array{Int,2}, car_pos_a::Int, # calcul
                        first_line::Int, last_line::Int # lines modified
                    )

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
                        if (car_pos_a == b0)
                            print("+1 ")
                        end

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

    if (car_pos_a == b0)
        println("seq seems to be: ", due_to_sequence_removed)
    end

    println(violations_caused)

    return M1, violations_caused
end


"""
        compute_delta2_for_b0(
                        solution::Solution, instance::Instance, # instance
                        M1::Array{Int,2}, sequence::Array{Int,1}, car_pos_a::Int, # calcul
                        first_line::Int, last_line::Int # lines modified
                    )

For factorization
"""
function compute_delta2_for_b0(
                        solution::Solution, instance::Instance, # instance
                        M1::Array{Int,2}, sequence::Array{Int,1}, car_pos_a::Int, # calcul
                        first_line::Int, last_line::Int # lines modified
                    )

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
                    print("here ")
                    if instance.RC_flag[C_out, option] && M1[option, modified_sequence] > instance.RC_p[option]
                        delta2 -= 1
                        print("-1 ")
                    end
                    if instance.RC_flag[C_in, option] && M1[option, modified_sequence] >= instance.RC_p[option]
                        print("+1 ")
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

    println("\t\t", delta2)

    return delta2
end


"""
        compute_delta1(
                        solution::Solution, instance::Instance, # instance
                        M1::Array{Int,2}, sequence::Array{Int,1}, cursor::Int, car_pos_a::Int, # calcul
                        first_line::Int, last_line::Int # lines modified
                    )

For factorization
"""
function compute_delta1(
                        solution::Solution, instance::Instance, # instance
                        M1::Array{Int,2}, sequence::Array{Int,1}, cursor::Int, car_pos_a::Int, # calcul
                        first_line::Int, last_line::Int # lines modified
                    )

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

    if (car_pos_a == instance.nb_late_prec_day+1 && cursor == car_pos_a)
        println("\t", delta1)
    end

    return delta1
end



"""
        compute_delta2(
                        solution::Solution, instance::Instance, # instance
                        M1::Array{Int,2}, sequence::Array{Int,1}, index::Int, car_pos_a::Int, # calcul
                        first_line::Int, last_line::Int, # lines modified
                        delta2_for_objective
                    )

For factorization
"""
function compute_delta2(
            solution::Solution, instance::Instance, # instance
            M1::Array{Int,2}, sequence::Array{Int,1}, index::Int, car_pos_a::Int, # calcul
            first_line::Int, last_line::Int, # lines modified
            delta2_for_objective
        )
    # Delta 2 is compute with intelligence and vivacity...
    # this is not for unsmart boïs
    # TODO: verification needed (really really reeeeeally NEEDED)
    delta2_for_objective[index] = delta2_for_objective[index-1]
    for option in first_line:last_line
        # What is called in the article: delta_{b-q(o_j)}
        # there is one sequence too far from us now
        sequence_unreaching_it = index - instance.RC_q[option]
        if sequence_unreaching_it > 0
            if xor(instance.RC_flag[sequence[index], option], instance.RC_flag[solution.sequence[car_pos_a], option])
                # The last sequence is now more violated than before
                if instance.RC_flag[sequence[index]]
                    if M1[option, sequence_unreaching_it] > instance.RC_p[option]
                        delta2_for_objective[index] += 1
                    end
                end
                # Car was counted as a violation
                if instance.RC_flag[solution.sequence[car_pos_a]]
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
            if xor(instance.RC_flag[sequence[first_unreached_index], option], instance.RC_flag[solution.sequence[car_pos_a], option])
                # The new sequence is now more violated than before
                if instance.RC_flag[sequence[first_unreached_index]]
                    if M1[option, new_modified_sequence] > instance.RC_p[option]
                        delta2_for_objective[index] -= 1
                    end
                end
                # Car dropped one violation
                if instance.RC_flag[solution.sequence[car_pos_a]]
                    if M1[option, new_modified_sequence] >= instance.RC_p[option]
                        delta2_for_objective[index] += 1
                    end
                end
            end
        else # sequence was at the end, no-one is getting out
            # Car may cause one violation
            if instance.RC_flag[solution.sequence[car_pos_a]]
                if M1[option, new_modified_sequence] >= instance.RC_p[option]
                    delta2_for_objective[index] += 1
                end
            end
        end
    end

    return delta2_for_objective
end
