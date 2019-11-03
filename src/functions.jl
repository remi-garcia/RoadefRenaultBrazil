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
    move_insertion!(solution::Solution, car_pos_a::Int, car_pos_b::Int, instance::Instance)

Inserts the car of index `car_pos_a` before at index `car_pos_b` in `solution.sequence`.
Updates `solution.M1`, `solution.M2` and `solution.M3`.
"""
function move_insertion!(solution::Solution, car_pos_a::Int, car_pos_b::Int, instance::Instance)
    car_inserted = solution.sequence[car_pos_a]
    if car_pos_a < car_pos_b
        for car_moved_pos in car_pos_a:(car_pos_b-1)
            solution.sequence[car_moved_pos] = solution.sequence[car_moved_pos+1]
        end
        solution.sequence[car_pos_b] = car_inserted
    end
    if car_pos_a > car_pos_b
        for car_moved_pos in car_pos_a:-1:(car_pos_b+1)
            solution.sequence[car_moved_pos] = solution.sequence[car_moved_pos-1]
        end
        solution.sequence[car_pos_b] = car_inserted
    end

    update_matrices!(solution, solution.n, instance)

    # TODO
    return Solution
end

"""
    cost_move_exchange(solution::Solution, car_pos_a::Int, car_pos_b::Int,
                       instance::Instance, objective::Int)

Return the cost of the exchange of the car `car_pos_a` with the car `car_pos_b` with respect to
objective `objective`. A negative cost means that the move is interesting with
respect to objective `objective`.
CAREFUL: Return a delta !
"""
function cost_move_exchange(solution::Solution, car_pos_a::Int, car_pos_b::Int,
                            instance::Instance, objective::Int)
    #TODO it might be important that objective is a vector of Int, then we could
    #return a vector of cost.

    # objective should take values between 1 and 3.
    @assert objective >= 1
    @assert objective <= 3

    cost_on_objective = zeros(Int, 3)

    if objective >= 1 #Must improve or keep HPRC
        for option in 1:instance.nb_HPRC
            # No cost if both have it / have it not
            if instance.RC_flag[solution.sequence[car_pos_a], option] != instance.RC_flag[solution.sequence[car_pos_b], option]
                #TODO: Rewrite code or swap indexes ?
                if instance.RC_flag[solution.sequence[car_pos_b], option]
                    car_pos_a,car_pos_b = car_pos_b,car_pos_a
                end
                # New option here -> increasing cost
                last_ended_sequence = car_pos_b - instance.RC_q[option]
                if last_ended_sequence > 0
                    cost_on_objective[1] += solution.M3[option, car_pos_b] - solution.M3[option, last_ended_sequence]
                else
                    cost_on_objective[1] += solution.M3[option, car_pos_b]
                end
                # No option anymore -> decreasing cost
                last_ended_sequence = car_pos_a - instance.RC_q[option]
                if last_ended_sequence > 0
                    cost_on_objective[1] -= solution.M2[option, car_pos_a] - solution.M2[option, last_ended_sequence]
                else
                    cost_on_objective[1] -= solution.M2[option, car_pos_a]
                end
            end
        end
    end
    if objective >= 2 #Must improve or keep HPRC and LPRC
        for option in (instance.nb_HPRC+1):(instance.nb_HPRC+instance.nb_LPRC)
            # No cost if both have it / have it not
            if instance.RC_flag[solution.sequence[car_pos_a], option] != instance.RC_flag[solution.sequence[car_pos_b], option]
                #TODO: Rewrite code or swap indexes ?
                if instance.RC_flag[solution.sequence[car_pos_b], option]
                    car_pos_a,car_pos_b = car_pos_b,car_pos_a
                end
                # New option here -> increasing cost
                last_ended_sequence = car_pos_b - instance.RC_q[option]
                if last_ended_sequence > 0
                    cost_on_objective[2] += solution.M3[option, car_pos_b] - solution.M3[option, last_ended_sequence]
                else
                    cost_on_objective[2] += solution.M3[option, car_pos_b]
                end
                # No option anymore -> decreasing cost
                last_ended_sequence = car_pos_a - instance.RC_q[option]
                if last_ended_sequence > 0
                    cost_on_objective[2] -= solution.M2[option, car_pos_a] - solution.M2[option, last_ended_sequence]
                else
                    cost_on_objective[2] -= solution.M2[option, car_pos_a]
                end
            end
        end
    end
    if objective >= 3 #Must improve or keep HPRC and LPRC and PCC
        #TODO
    end

    #return cost_on_objective
    return sum(cost_on_objective[i]*WEIGHTS_OBJECTIVE_FUNCTION[i] for i in 1:3)
end

"""
    cost_move_insertion(solution::Solution, car_pos_a::Int, car_pos_b::Int,
                        instance::Instance, objective::Int)

Return the cost of the insertion of the car `car_pos_a` before the car `car_pos_b` with respect
to objective `objective`. A negative cost means that the move is interesting
with respect to objective `objective`.
CAREFUL: Return a delta !
"""
function cost_move_insertion(solution::Solution, car_pos_a::Int, car_pos_b::Int,
                             instance::Instance, objective::Int)
    #TODO it might be important that objective is a vector of Int, then we could
    #return a vector of cost.

    # objective should take values between 1 and 3.
    @assert objective >= 1
    @assert objective <= 3

    z = cost(solution, instance, 3)
    s = deepcopy(solution)
    move_insertion!(s, car_pos_a, car_pos_b, instance)
    Z = cost(s, instance, 3)

    # TODO
    return Z-z
end

"""
    cost(solution::Solution, instance::Instance, objective::Int)

Return the (partial) cost of the solution s.
"""
function cost(solution::Solution, instance::Instance, objective::Int)
    value = 0
    for car in 1:instance.n
        for option in 1:instance.nb_HPRC
            value += max(0 , solution.M1[car, option] - instance.RC_p[solution.sequence[car]])
        end
    end
    z = value*WEIGHTS_OBJECTIVE_FUNCTION[1]
    value = 0

    if objective >= 2 #Must improve or keep HPRC and LPRC
        for car in 1:instance.n
            for option in (instance.nb_HPRC+1):(instance.nb_HPRC+instance.nb_LPRC)
                value += max(0 , solution.M1[car, option] - instance.RC_p[solution.sequence[car]])
            end
        end
    end
    z += value*WEIGHTS_OBJECTIVE_FUNCTION[2]
    value = 0

    if objective >= 3 #Must improve or keep HPRC and LPRC and PCC
        #TODO
    end
    z += value*WEIGHTS_OBJECTIVE_FUNCTION[3]

    return z
end


"""
    HPRC_level(solution::Solution, index::Int, instance::Instance)

Return the HPRC level of `index` car in the current `solution`.
"""
function HPRC_level(solution::Solution, index::Int, instance::Instance)
    return sum(solution.M2[k, index] for k in 1:instance.nb_HPRC)
end

"""
    same_HPRC(solution::Solution, car_pos_a::Int, car_pos_b::Int, instance::Instance)

Return `true` if car `car_pos_a` and `car_pos_b` have the same HPRC level. `false` otherwise.
"""
function same_HPRC(solution::Solution, car_pos_a::Int, car_pos_b::Int, instance::Instance)
    return HPRC_level(solution, car_pos_a, instance) == HPRC_level(solution, car_pos_b, instance)
end
