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


        #-------------------------------------------------------#
        #                                                       #
        #                        Cost                           #
        #                                                       #
        #-------------------------------------------------------#

"""
    cost(solution::Solution, instance::Instance, objective::Int)

Return the (partial) set of values of objectives (without weight) of the solution s.
"""
function cost(solution::Solution, instance::Instance, objective::Int)
    cost_on_objective = zeros(Int, 3)

    value = 0
    for car in 1:instance.nb_cars
        for option in 1:instance.nb_HPRC
            value += max(0 , solution.M1[option, car] - instance.RC_p[option])
        end
    end
    cost_on_objective[1] = value

    value = 0
    if objective >= 2 #Must improve or keep HPRC and LPRC
        for car in 1:instance.nb_cars
            for option in (instance.nb_HPRC+1):(instance.nb_HPRC+instance.nb_LPRC)
                value += max(0 , solution.M1[option, car] - instance.RC_p[option])
            end
        end
    end
    cost_on_objective[2] = value

    if objective >= 3 #Must improve or keep HPRC and LPRC and PCC
        for i in 2:instance.nb_cars
            if instance.color_code[i] != instance.color_code[i-1]
                cost_on_objective[3] += 1
            end
        end
    end

    return cost_on_objective
end


"""
    weighted_sum(cost_solution::Array{Int, 1})

Return the weighted sum of the (partial) solution s.
"""
function weighted_sum(cost_solution::Array{Int, 1}, objective::Int)
    # objective should take values between 1 and 3.
    @assert objective >= 1
    @assert objective <= 3
    return sum(cost_solution[i] * WEIGHTS_OBJECTIVE_FUNCTION[i] for i in 1:objective)
end


"""
    weighted_sum(cost_solution::Array{Int, 1})

Return the weighted sum of the (partial) solution s.
"""
function weighted_sum(solution::Solution, instance::Instance, objective::Int)
    # objective should take values between 1 and 3.
    @assert objective >= 1
    @assert objective <= 3
    return weighted_sum(cost(solution, instance, objective), objective)
end

"""
    print_cost(solution::Solution, instance::Instance)

Print the objective value of the solution.
"""
function print_cost(solution::Solution, instance::Instance)
    cost_solution = cost(solution, instance, 3)
    println("\tHPRC violations: ", cost_solution[1])
    println("\tLPRC violations: ", cost_solution[2])
    println("\tPCC  violations: ", cost_solution[3])
    println("\tObjective value is ",weighted_sum(cost_solution, 3))
end


        #-------------------------------------------------------#
        #                                                       #
        #                      RC_value                         #
        #                                                       #
        #-------------------------------------------------------#

"""
    HPRC_level(solution::Solution, index::Int, instance::Instance)

Return the HPRC level of `index` car in the current `solution`.
"""
function HPRC_level(solution::Solution, index::Int, instance::Instance)
    return sum(solution.M2[option, index] for option in 1:instance.nb_HPRC)
end

"""
    same_HPRC(solution::Solution, car_pos_a::Int, car_pos_b::Int, instance::Instance)

Return `true` if car `car_pos_a` and `car_pos_b` have the same HPRC level. `false` otherwise.
"""
function same_HPRC(solution::Solution, car_pos_a::Int, car_pos_b::Int, instance::Instance)
    return HPRC_level(solution, car_pos_a, instance) == HPRC_level(solution, car_pos_b, instance)
end

function HPRC_value(car::Int, instance::Instance)
    car_HPRC_value = "0"
    for option in 1:instance.nb_HPRC
        car_HPRC_value = string(Int(instance.RC_flag[car, option])) * car_HPRC_value
    end
    return parse(Int, car_HPRC_value, base = 2)
end

function RC_value(car::Int, instance::Instance)
    car_RC_value = "0"
    for option in 1:(instance.nb_LPRC+instance.nb_HPRC)
        car_RC_value = string(Int(instance.RC_flag[car, option])) * car_RC_value
    end
    return parse(Int, string(car_RC_value), base = 2)
end

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
