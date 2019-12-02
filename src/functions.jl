#-------------------------------------------------------------------------------
# File: functions.jl
# Description: This file contains functions that are used in ILS and VNS.
# Date: October 31, 2019
# Author: Jonathan Fontaine, Killian Fretaud, Rémi Garcia,
#         Boualem Lamraoui, Benoît Le Badezet, Benoit Loger
#-------------------------------------------------------------------------------

# More readable
include("move_insertion.jl")
include("move_exchange.jl")

"""
    greedy_add!(solution::Solution, instance::Instance, k::Int, objectives::Int)

Reinserts last car in the sequence of `solution`.
"""
function greedy_add!(solution::Solution, instance::Instance, k::Int, objectives::Int)
    @assert objectives <= 3
    @assert objectives >= 1
    b0 = instance.nb_late_prec_day + 1
    # TODO:
    # Cost move insertion do more work than necessary.
    # It will compute delta for instance.nb_cars-k to instance.nb_cars
    # Such deltas will be false. But it is easier to compute it this way
    costs = cost_move_insertion(solution, instance.nb_cars, instance, objectives)
    delta = weighted_sum(costs[b0, :])
    # Last delta is a whole new addition at the end of the sequence
    last_delta = zeros(Int, 3)
    car = solution.sequence[instance.nb_cars]
    if objectives >= 1
        for option in 1:instance.nb_HPRC
            if instance.RC_flag[car, option]
                last_sequence_untouched = (instance.nb_cars-k) - instance.RC_q[option]
                if last_sequence_untouched >= 1
                    last_delta[1] += solution.M3[option, (instance.nb_cars-k)-1] - solution.M3[option, last_sequence_untouched]
                elseif instance.nb_cars-k >= 1
                    last_delta[1] += solution.M3[option, (instance.nb_cars-k)-1]
                end
            end
        end
    end
    if objectives >= 2
        for option in (instance.nb_HPRC+1):(instance.nb_HPRC+instance.nb_LPRC)
            if instance.RC_flag[car, option]
                last_sequence_untouched = (instance.nb_cars-k) - instance.RC_q[option]
                if last_sequence_untouched >= 1
                    last_delta[2] += solution.M3[option, (instance.nb_cars-k)-1] - solution.M3[option, last_sequence_untouched]
                elseif instance.nb_cars-k >= 1
                    last_delta[2] += solution.M3[option, (instance.nb_cars-k)-1]
                end
            end
        end
    end
    if objectives >= 3
        for option in (instance.nb_HPRC+1):(instance.nb_HPRC+instance.nb_LPRC)
            if ((instance.nb_cars-k)-1 >= 1
            && instance.color_code[solution.sequence[car]] != instance.color_code[solution.sequence[instance.nb_cars-k]])
                last_delta[3] += 1
            end
        end
    end
    best_delta = weighted_sum(last_delta)
    best_position = instance.nb_cars-k

    # Other delta must be checked
    for position in b0:((instance.nb_cars-k)-1)
        delta = weighted_sum(costs[position, :])
        if delta < best_delta
            best_delta = delta
            best_position = position
        end
    end

    # We have a best place
    for j in (best_position+1):instance.nb_cars
        solution.sequence[j] = solution.sequence[j-1]
    end
    solution.sequence[best_position] = car

    # For all options
    for option in 1:instance.nb_HPRC+instance.nb_LPRC
        first_modified_sequence = max(best_position - instance.RC_q[option] + 1, 1)

        # Shift right late sequences for M1
        for late_sequence in best_position+1:instance.nb_cars
            solution.M1[option, late_sequence-1] = solution.M1[option, late_sequence]
        end

        # M1 may increase
        if instance.RC_flag[car, option]
            for modified_sequence in first_modified_sequence:best_position
                solution.M1[option, modified_sequence] += 1
            end
        end

        # M1 may decrease
        for modified_sequence in first_modified_sequence:best_position
            new_position_unreached = modified_sequence + instance.RC_q[option]
            if new_position_unreached < instance.nb_cars-k
                if instance.RC_flag[solution.sequence[new_position_unreached], option]
                    solution.M1[option, modified_sequence] -= 1
                end
            end
        end

        # Next sequences are shifted and change w.r.t variation
        for modified_sequence in first_modified_sequence:instance.nb_cars-k
            # M2 and M3 may change
            if modified_sequence == 1
                solution.M2[option, modified_sequence] = 0
                solution.M3[option, modified_sequence] = 0
            else
                solution.M2[option, modified_sequence] = solution.M2[option, modified_sequence-1]
                solution.M3[option, modified_sequence] = solution.M3[option, modified_sequence-1]
            end
            if solution.M1[option, modified_sequence] >= instance.RC_p[option]
                solution.M3[option, modified_sequence] += 1
                # M2 is >
                if solution.M1[option, modified_sequence] > instance.RC_p[option]
                    solution.M2[option, modified_sequence] += 1
                end
            end
        end
    end

    return solution
end

"""
    find_critical_cars(solution::Solution, instance::Instance,
                       objectives::BitArray{1})

Returns the set cars involved in at least one HPRC violation and/or one LPRC
violation.
"""
function find_critical_cars(solution::Solution, instance::Instance,
                            objectives::BitArray{1})
    @assert length(objectives) == 2
    @assert true in objectives
    if objectives[1]
        first_option = 1
    else
        first_option = instance.nb_HPRC+1
    end
    if objectives[2]
        last_option = instance.nb_HPRC+instance.nb_LPRC
    else
        last_option = instance.nb_HPRC
    end

    critical_cars = Set{Int}()
    b0 = instance.nb_late_prec_day + 1
    for index_car in b0:instance.nb_cars
        for option in first_option:last_option
            if solution.M1[option, index_car] > instance.RC_p[option]
                index_car_lim = index_car + min(instance.RC_p[option], instance.nb_cars-index_car)
                for index_car_add in index_car:index_car_lim
                    if instance.RC_flag[solution.sequence[index_car_add], option]
                        push!(critical_cars, index_car_add)
                    end
                end
            end
        end
    end
    return collect(critical_cars)
end

find_critical_cars(solution::Solution, instance::Instance, objectives::Int) =
    find_critical_cars(solution::Solution, instance::Instance, [trues(objectives) ; falses(2-objectives)])

"""
    remove!(solution_init::Solution, instance::Instance,
            k::Int, crit::Array{Int, 1})

Removes `k` critical cars of the sequence of `solution_init`.
"""
function remove!(solution::Solution, instance::Instance,
                 k::Int, crit::Array{Int, 1})
    indices = sort(randperm(length(crit))[1:k])
    crit_sort = sort(crit, rev = true)
    for i in 1:k
        position = crit_sort[indices[i]]
        car = solution.sequence[position]
        for j in position:(instance.nb_cars-1)
            solution.sequence[j] = solution.sequence[j+1]
        end
        solution.sequence[instance.nb_cars] = car

        # For all options
        for option in 1:instance.nb_HPRC+instance.nb_LPRC
            first_modified_sequence = max(position - instance.RC_q[option] + 1, 1)

            # M1 may decrease
            if instance.RC_flag[car, option]
                for modified_sequence in first_modified_sequence:position
                    solution.M1[option, modified_sequence] -= 1
                end
            end

            # M1 may increase
            for modified_sequence in first_modified_sequence:(position-1)
                new_position_reached = modified_sequence + instance.RC_q[option]
                if new_position_reached < instance.nb_cars-i
                    if instance.RC_flag[solution.sequence[new_position_reached], option]
                        solution.M1[option, modified_sequence] += 1
                    end
                end
            end

            # Shift left late sequences for M1
            for late_sequence in position:instance.nb_cars-1
                solution.M1[option, late_sequence] = solution.M1[option, late_sequence+1]
            end

            # Next sequences are shifted and change w.r.t variation
            for modified_sequence in first_modified_sequence:instance.nb_cars-i
                # M2 and M3 may change
                if modified_sequence == 1
                    solution.M2[option, modified_sequence] = 0
                    solution.M3[option, modified_sequence] = 0
                else
                    solution.M2[option, modified_sequence] = solution.M2[option, modified_sequence-1]
                    solution.M3[option, modified_sequence] = solution.M3[option, modified_sequence-1]
                end
                if solution.M1[option, modified_sequence] >= instance.RC_p[option]
                    solution.M3[option, modified_sequence] += 1
                    # M2 is >
                    if solution.M1[option, modified_sequence] > instance.RC_p[option]
                        solution.M2[option, modified_sequence] += 1
                    end
                end
            end

            # nb_cars - (i+1) is a deleted column
            solution.M2[option, instance.nb_cars-i+1] = 0
            solution.M3[option, instance.nb_cars-i+1] = 0
        end
    end

    return solution
end

"""
    cost(solution::Solution, instance::Instance, objectives::BitArray{1})

Returns the (partial) set of objective values (without weights) of `solution`.
"""
function cost(solution::Solution, instance::Instance, objectives::BitArray{1})
    @assert length(objectives) == 3
    @assert true in objectives
    cost_on_objective = zeros(Int, 3)

    if objectives[1]
        for car in 1:instance.nb_cars
            for option in 1:instance.nb_HPRC
                cost_on_objective[1] += max(0 , solution.M1[option, car] - instance.RC_p[option])
            end
        end
    end

    if objectives[2]
        for car in 1:instance.nb_cars
            for option in (instance.nb_HPRC+1):(instance.nb_HPRC+instance.nb_LPRC)
                cost_on_objective[2] += max(0 , solution.M1[option, car] - instance.RC_p[option])
            end
        end
    end

    if objectives[3]
        for i in 2:instance.nb_cars
            if instance.color_code[solution.sequence[i]] != instance.color_code[solution.sequence[i-1]]
                cost_on_objective[3] += 1
            end
        end
    end

    return cost_on_objective
end

"""
    cost(solution::Solution, instance::Instance, objectives::Int)

Returns the set of unweighted values for objectives 1 to `objectives` of `solution`.
"""
cost(solution::Solution, instance::Instance, objectives::Int) =
    cost(solution::Solution, instance::Instance, [trues(objectives) ; falses(3-objectives)])

cost(solution::Solution, instance::Instance) =
    cost(solution::Solution, instance::Instance, 3)


"""
    weighted_sum(cost_solution::Array{Int, 1})

Returns the partial weighted sum of the objective values.
"""
function weighted_sum(cost_solution::Array{Int, 1})
    return sum(cost_solution[i] * WEIGHTS_OBJECTIVE_FUNCTION[i] for i in 1:length(cost_solution))
end

weighted_sum(solution::Solution, instance::Instance) =
    weighted_sum(cost(solution, instance))

"""
    print_cost(solution::Solution, instance::Instance)

Prints the objective values of the solution.
"""
function print_cost(solution::Solution, instance::Instance)
    cost_solution = cost(solution, instance, 3)
    println("\tHPRC violations: ", cost_solution[1])
    println("\tLPRC violations: ", cost_solution[2])
    println("\tPCC  violations: ", cost_solution[3])
    println("\tObjective value is ", weighted_sum(cost_solution))
end

# RC functions

"""

"""
function HPRC_value(car::Int, instance::Instance)
    car_HPRC_value = "0"
    for option in 1:instance.nb_HPRC
        car_HPRC_value = string(Int(instance.RC_flag[car, option])) * car_HPRC_value
    end
    return parse(Int, car_HPRC_value, base = 2)
end

"""

"""
function RC_value(car::Int, instance::Instance)
    car_RC_value = "0"
    for option in 1:(instance.nb_LPRC+instance.nb_HPRC)
        car_RC_value = string(Int(instance.RC_flag[car, option])) * car_RC_value
    end
    return parse(Int, string(car_RC_value), base = 2)
end

"""

"""
function is_sequence_valid(sequence::Array{Int, 1}, n::Int, instance::Instance)
    counter = 1
    for car_pos in 2:n
        if instance.color_code[sequence[car_pos-1]] == instance.color_code[sequence[car_pos]]
            counter += 1
        else
            counter = 1
        end
        if counter > instance.nb_paint_limitation && counter >= instance.nb_late_prec_day+1
            return false
        end
    end
    return true
end
