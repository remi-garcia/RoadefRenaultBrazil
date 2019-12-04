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
    sequence_insert!(sequence::Array{Int, 1}, index_remove::Int, index_insert::Int)

Delete the item at `index_remove` and insert at `index_insert` in the sequence.
"""
function sequence_insert!(sequence::Array{Int, 1}, index_remove::Int, index_insert::Int)
    temp = sequence[index_remove]
    if index_remove < index_insert
        for k in index_remove:(index_insert-1)
            sequence[k] = sequence[k+1]
        end
    else
        for k in index_remove:-1:(index_insert+1)
            sequence[k] = sequence[k-1]
        end
    end
    sequence[index_insert] = temp
end

"""

"""
function penalize_costs!(costs::Array{Int, 2}, init_position::Int,
                         solution::Solution, instance::Instance)
    sequence = copy(solution.sequence)
    sequence_insert!(sequence, init_position, 1)

    for position in 1:(solution.length-1)
        if !is_sequence_valid(sequence, solution.length, instance)
            costs[position, :] .= instance.nb_cars
        end
        sequence[position], sequence[position+1] = sequence[position+1], sequence[position]
    end

    return costs
end

"""
    greedy_add!(solution::Solution, instance::Instance, k::Int, objectives::Int)

Reinserts last car in the sequence of `solution`.
"""
function greedy_add!(solution::Solution, instance::Instance, position_car::Int,
                     objectives::Int, valid_sequence::Bool = false)
    @assert objectives <= 3
    @assert objectives >= 1
    b0 = instance.nb_late_prec_day + 1
    costs = cost_move_insertion(solution, position_car, instance, objectives)
    if valid_sequence
        solution.length += 1
        penalize_costs!(costs, position_car, solution, instance)
        solution.length -= 1
    end
    delta = weighted_sum(costs[b0, :])
    best_delta = delta
    best_position = b0
    for position in (b0+1):solution.length
        delta = weighted_sum(costs[position, :])
        if delta < best_delta
            best_delta = delta
            best_position = position
        end
    end
    #Limit case:
    # No position allows a valid sequence
    if valid_sequence && best_delta == typemax(Int)
        return greedy_add!(solution, instance, position_car-1, objectives, valid_sequence)
    end
    solution.length += 1
    move_insertion!(solution, position_car, best_position, instance)

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
    for index_car in b0:solution.length
        for option in first_option:last_option
            if solution.M1[option, index_car] > instance.RC_p[option]
                index_car_lim = index_car + min(instance.RC_p[option], solution.length-index_car)
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
        move_insertion!(solution, position, instance.nb_cars, instance)
    end
    solution.length -= k

    return solution
end

"""
    cost(solution::Solution, instance::Instance, objectives::BitArray{1})

Returns the (partial) set of objective values (without weights) of `solution`.
"""
function cost(solution::Solution, instance::Instance, objectives::BitArray{1})
    @assert length(objectives) == 3
    @assert true in objectives
    @assert solution.length == instance.nb_cars
    cost_on_objective = zeros(Int, 3)

    if objectives[1]
        for car in 1:solution.length
            for option in 1:instance.nb_HPRC
                cost_on_objective[1] += max(0 , solution.M1[option, car] - instance.RC_p[option])
            end
        end
    end

    if objectives[2]
        for car in 1:solution.length
            for option in (instance.nb_HPRC+1):(instance.nb_HPRC+instance.nb_LPRC)
                cost_on_objective[2] += max(0 , solution.M1[option, car] - instance.RC_p[option])
            end
        end
    end

    if objectives[3]
        for i in 2:solution.length
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
#TODO: why n ?
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
