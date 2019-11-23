#-------------------------------------------------------------------------------
# File: functions.jl
# Description: This file contains functions that are used in VNS and ILS.
# Date: October 31, 2019
# Author: Jonathan Fontaine, Killian Fretaud, Rémi Garcia,
#         Boualem Lamraoui, Benoît Le Badezet, Benoit Loger
#-------------------------------------------------------------------------------

# More readable
include("move_insertion.jl")
include("move_exchange.jl")

"""
    cost(solution::Solution, instance::Instance, objectives::BitArray{1})

Returns the (partial) set of objective values (without weights) of `solution`.
"""
function cost(solution::Solution, instance::Instance, objectives::BitArray{1})
    @assert length(objectives) == 3
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
    cost(solution::Solution, instance::Instance, objective::Int)

Returns the set of unweighted values for objectives 1 to `objective` of `solution`.
"""
cost(solution::Solution, instance::Instance, objective::Int) =
    cost(solution::Solution, instance::Instance, [trues(objective) ; falses(3-objective)])

"""
    weighted_sum(cost_solution::Array{Int, 1})

Returns the partial weighted sum of the objective values.
"""
function weighted_sum(cost_solution::Array{Int, 1}, objective::Int)
    # objective should take values between 1 and 3.
    @assert objective >= 1
    @assert objective <= 3
    return sum(cost_solution[i] * WEIGHTS_OBJECTIVE_FUNCTION[i] for i in 1:objective)
end

weighted_sum(solution::Solution, instance::Instance, objective::Int) =
    weighted_sum(cost(solution, instance, objective), objective)

"""
    print_cost(solution::Solution, instance::Instance)

Prints the objective values of the solution.
"""
function print_cost(solution::Solution, instance::Instance)
    cost_solution = cost(solution, instance, 3)
    println("\tHPRC violations: ", cost_solution[1])
    println("\tLPRC violations: ", cost_solution[2])
    println("\tPCC  violations: ", cost_solution[3])
    println("\tObjective value is ",weighted_sum(cost_solution, 3))
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
