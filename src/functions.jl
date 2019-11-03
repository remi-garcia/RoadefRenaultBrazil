#-------------------------------------------------------------------------------
# File: functions.jl
# Description: This file contains functions that are used in VNS and ILS.
# Date: October 31, 2019
# Author: Jonathan Fontaine, Killian Fretaud, Rémi Garcia,
#         Boualem Lamraoui, Benoît Le Badezet, Benoit Loger
#-------------------------------------------------------------------------------

"""
    move_exchange!(solution::Solution, car_pos_a::Int, car_pos_b::Int, instance::Instance)

Interverts the car `car_pos_a` with the car `car_pos_b` in `solution.sequence`. Updates
`solution.M1`, `solution.M2` and `solution.M3`.
"""
function move_exchange!(solution::Solution, car_pos_a::Int, car_pos_b::Int, instance::Instance)
    if car_pos_a > car_pos_b
        return move_exchange!(solution, car_pos_b, car_pos_a, instance)
    end
    if car_pos_a == car_pos_b
        return solution
    end
    car_a = solution.sequence[car_pos_a]
    car_b = solution.sequence[car_pos_b]
    solution.sequence[car_pos_a], solution.sequence[car_pos_b] = solution.sequence[car_pos_b], solution.sequence[car_pos_a]
    #update_matrices!(solution, solution.n, instance)
    for option in 1:(instance.nb_HPRC + instance.nb_LPRC)
        if xor(instance.RC_flag[car_a, option], instance.RC_flag[car_b, option])
            plusminusone = 1
            if instance.RC_flag[car_a, option]
                plusminusone = -1
            end
            first_modified_pos = car_pos_a - instance.RC_q[option] + 1
            if first_modified_pos < 1
                first_modified_pos = 1
            end
            for car_pos in first_modified_pos:car_pos_a
                solution.M1[option, car_pos] += plusminusone
                if car_pos == 1
                    solution.M2[option, car_pos] = 0
                    solution.M3[option, car_pos] = 0
                else
                    solution.M2[option, car_pos] = solution.M2[option, car_pos-1]
                    solution.M3[option, car_pos] = solution.M3[option, car_pos-1]
                end
                # M3 is >=
                if solution.M1[option, car_pos] >= instance.RC_p[option]
                    solution.M3[option, car_pos] += 1
                    # M2 is >
                    if solution.M1[option, car_pos] > instance.RC_p[option]
                        solution.M2[option, car_pos] += 1
                    end
                end
            end

            second_modified_pos = car_pos_b - instance.RC_q[option] + 1
            if second_modified_pos < 1
                second_modified_pos = 1
            end
            for car_pos in second_modified_pos:car_pos_b
                solution.M1[option, car_pos] -= plusminusone
                if car_pos == 1
                    solution.M2[option, car_pos] = 0
                    solution.M3[option, car_pos] = 0
                else
                    solution.M2[option, car_pos] = solution.M2[option, car_pos-1]
                    solution.M3[option, car_pos] = solution.M3[option, car_pos-1]
                end
                # M3 is >=
                if solution.M1[option, car_pos] >= instance.RC_p[option]
                    solution.M3[option, car_pos] += 1
                    # M2 is >
                    if solution.M1[option, car_pos] > instance.RC_p[option]
                        solution.M2[option, car_pos] += 1
                    end
                end
            end
        end
    end
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
    return 1
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
    return 1
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
