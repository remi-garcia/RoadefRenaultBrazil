#-------------------------------------------------------------------------------
# File: functions.jl
# Description: This file contains functions that are used in VNS and ILS.
# Date: October 31, 2019
# Author: Jonathan Fontaine, Killian Fretaud, Rémi Garcia,
#         Boualem Lamraoui, Benoît Le Badezet, Benoit Loger
#-------------------------------------------------------------------------------

"""
    move_exchange!(solution::Solution, i::Int, j::Int, instance::Instance)

Interverts the car `i` with the car `j` in `solution.sequence`. Updates
`solution.M1`, `solution.M2` and `solution.M3`.
"""
function move_exchange!(solution::Solution, i::Int, j::Int, instance::Instance)
    # TODO
    return Solution
end

"""
    move_insertion!(solution::Solution, i::Int, j::Int, instance::Instance)

Inserts the car `i` before the car `j` in `solution.sequence`. Updates
`solution.M1`, `solution.M2` and `solution.M3`.
"""
function move_insertion!(solution::Solution, i::Int, j::Int, instance::Instance)
    # TODO
    return Solution
end

"""
    cost_move_exchange(solution::Solution, i::Int, j::Int,
                       instance::Instance, objective::Int)

Return the cost of the exchange of the car `i` with the car `j` with respect to
objective `objective`. A negative cost means that the move is interesting with
respect to objective `objective`.
"""
function cost_move_exchange(solution::Solution, i::Int, j::Int,
                            instance::Instance, objective::Int)
    #TODO it might be important that objective is a vector of Int, then we could
    #return a vector of cost.

    # objective should take values between 1 and 3.
    @assert objective >= 1
    @assert objective <= 3
    # TODO
    return 0
end

"""
    cost_move_insertion(solution::Solution, i::Int, j::Int,
                        instance::Instance, objective::Int)

Return the cost of the insertion of the car `i` before the car `j` with respect
to objective `objective`. A negative cost means that the move is interesting
with respect to objective `objective`.
"""
function cost_move_insertion(solution::Solution, i::Int, j::Int,
                             instance::Instance, objective::Int)
    #TODO it might be important that objective is a vector of Int, then we could
    #return a vector of cost.

    # objective should take values between 1 and 3.
    @assert objective >= 1
    @assert objective <= 3
    # TODO
    return 0
end

"""
    HPRC_level(solution::Solution, index::Int, instance::Instance)

Return the HPRC level of `index` car in the current `solution`.
"""
function HPRC_level(solution::Solution, index::Int, instance::Instance)
    return sum(solution.M2[k, index] for k in 1:instance.nb_HPRC)
end

"""
    same_HPRC(solution::Solution, i::Int, j::Int, instance::Instance)

Return `true` if car `i` and `j` have the same HPRC level. `false` otherwise.
"""
function same_HPRC(solution::Solution, i::Int, j::Int, instance::Instance)
    return HPRC_level(solution, i, instance) == HPRC_level(solution, j, instance)
end
