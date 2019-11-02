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
