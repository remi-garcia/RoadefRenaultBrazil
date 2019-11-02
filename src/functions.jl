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
    solution.sequence[i], solution.sequence[j] = solution.sequence[j], solution.sequence[i]
    update_matrices!(solution, solution.n, instance)
    # for k in 1:(instance.nb_HPRC + instance.nb_LPRC)
    #     if xor(instance.RC_flag[i, k], instance.RC_flag[j, k])
    #         plusminusone = 1
    #         if instance.RC_flag[i, k]
    #             plusminusone = -1
    #         end
    #         pos1 = i - (instance.RC_q[k] - 1)
    #         if pos1 < 1
    #             pos1 = 1
    #         end
    #         for l in pos1:i
    #             solution.M1[k, l] += plusminusone
    #         end
    #         pos2 = j - (instance.RC_q[k] - 1)
    #         if pos2 < 1
    #             pos2 = 1
    #         end
    #         for l in pos2:j
    #             solution.M1[k, l] -= plusminusone
    #         end
    #         pos1 -= 1
    #         if pos1 < 1
    #             pos1 = 1
    #         end
    #         cpt1 = solution.M2[k, pos1]
    #         cpt2 = solution.M3[k, pos1]
    #         for l in pos1:solution.n
    #             if solution.M1[k, l] > instance.RC_p[k]
    #                 cpt1 += 1
    #                 solution.M2[k, l] = cpt1
    #             else
    #                 solution.M2[k, l] = cpt1
    #             end
    #             if solution.M1[k, l] >= instance.RC_p[k]
    #                 cpt2 += 1
    #                 solution.M3[k, l] = cpt2
    #             else
    #                 solution.M3[k, l] = cpt2
    #             end
    #         end
    #     end
    # end
    return solution
end

"""
    move_insertion!(solution::Solution, i::Int, j::Int, instance::Instance)

Inserts the car of index `i` before at index `j` in `solution.sequence`.
Updates `solution.M1`, `solution.M2` and `solution.M3`.
"""
function move_insertion!(solution::Solution, i::Int, j::Int, instance::Instance)
    car = solution.sequence[i]
    if i < j
        for k in i:(j-1)
            solution.sequence[k] = solution.sequence[k+1]
        end
        solution.sequence[j] = car
    end
    if i > j
        for k in i:-1:(j+1)
            solution.sequence[k] = solution.sequence[k-1]
        end
        solution.sequence[j] = car
    end

    update_matrices!(solution, solution.n, instance)

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
