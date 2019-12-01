#-------------------------------------------------------------------------------
# File: vns_lprc.jl
# Description: This files contains all function that are used in VNS_LPRC.
# Date: October 31, 2019
# Author: Jonathan Fontaine, Killian Fretaud, Rémi Garcia,
#         Boualem Lamraoui, Benoît Le Badezet, Benoit Loger
#-------------------------------------------------------------------------------

"""
    perturbation_VNS_LPRC_insertion!(solution::Solution, k::Int,
                                     critical_cars::Array{Int, 1},
                                     instance::Instance)

Deletes `k` random critical cars from the sequence. Inserts back those cars
according to a greedy criterion.
"""
function perturbation_VNS_LPRC_insertion!(solution::Solution, k::Int,
                                          critical_cars::Array{Int, 1},
                                          instance::Instance)
    remove!(solution, instance, k, critical_cars)
    for i in 1:k
        greedy_add_VNS_LPRC!(solution, instance, k-i, 2)
    end
    return solution
end

"""
    perturbation_VNS_LPRC_exchange!(solution::Solution, k::Int, instance::Instance)

Randomly applies k exchange between cars that are involved in the same
constraints.
"""
function perturbation_VNS_LPRC_exchange!(solution::Solution, k::Int, instance::Instance)
    # Dict that contain for each HRPC level an array of all index that have this HPRC level.
    all_list_same_HPRC = Dict{Int, Array{Int, 1}}()
    b0 = instance.nb_late_prec_day+1

    for index_car in b0:instance.nb_cars
        key_HPRC = HPRC_value(solution.sequence[index_car], instance)
        if !(key_HPRC in keys(all_list_same_HPRC))
            all_list_same_HPRC[key_HPRC] = Array{Int, 1}()
        end
        push!(all_list_same_HPRC[key_HPRC], index_car)
    end
    # Delete all HPRC with length less than 2 (Can't exchange 2 vehicles if there is less than 2)
    filter!(x -> length(x.second) >= 2, all_list_same_HPRC)

    for iterator in 1:k
        same_HPRC_array = rand(all_list_same_HPRC).second
        index_car_a = rand(same_HPRC_array)
        index_car_b = rand(same_HPRC_array)
        # Cannot be the same
        while index_car_a == index_car_b
            index_car_b = rand(same_HPRC_array)
        end
        move_exchange!(solution, index_car_a, index_car_b, instance)
    end

    return solution
end

"""
    perturbation_VNS_LPRC(solution::Solution, p::Int, k::Int, instance::Instance)

Calls both perturbations and return a new solution. This function does not
modify the solution given in parameters.
"""
function perturbation_VNS_LPRC(solution_init::Solution, p::Int, k::Int, instance::Instance)
    solution = deepcopy(solution_init)
    if p == 1
        perturbation_VNS_LPRC_exchange!(solution, k, instance)
    else
        critical_cars = find_critical_cars(solution, instance, 2)
        k = min(k, length(critical_cars))
        perturbation_VNS_LPRC_insertion!(solution, k, critical_cars, instance)
    end
    return solution
end

"""
    localSearch_VNS_LPRC!(solution::Solution, perturbation_exchange::Bool, instance::Instance)

Optimizes the weighted sum of first and second objectives. When
`perturbation_exchange` is `true` this function does not degrade the first
objective.
"""
function localSearch_VNS_LPRC!(solution::Solution, perturbation_exchange::Bool, instance::Instance)
    # useful variable
    b0 = instance.nb_late_prec_day+1
    all_list_same_HPRC = Dict{Int, Array{Int, 1}}()
    b0 = instance.nb_late_prec_day+1
    for index_car in b0:instance.nb_cars
        key_HPRC = HPRC_value(solution.sequence[index_car], instance)
        if !(key_HPRC in keys(all_list_same_HPRC))
            all_list_same_HPRC[key_HPRC] = Array{Int, 1}()
        end
        push!(all_list_same_HPRC[key_HPRC], index_car)
    end

    improved = true
    list = Array{Int, 1}()
    while improved
        improved = false
        critical_cars = find_critical_cars(solution, instance, 2)
        for index_car_a in critical_cars
            best_delta = -1 # < 0 to avoid to select delta = 0 if there is no improvment (avoid cycle)
            empty!(list)
            hprc_value = HPRC_value(solution.sequence[index_car_a], instance)
            for index_car_b in b0:instance.nb_cars
                if !perturbation_exchange || (index_car_a != index_car_b && index_car_b in all_list_same_HPRC[hprc_value])
                    delta = weighted_sum(cost_move_exchange(solution, index_car_a, index_car_b, instance, 2))
                    if delta < best_delta
                        list = [index_car_b]
                        best_delta = delta
                    elseif delta == best_delta
                        push!(list, index_car_b)
                    end
                end
            end
            if !isempty(list)
                index_car_b = rand(list)
                move_exchange!(solution, index_car_a, index_car_b, instance)
                improved = true
            end
        end
    end

    return solution
end

"""
    localSearch_intensification_VNS_LPRC_exchange!(solution::Solution, instance::Instance)

Optimizes the weighted sum of first and second objectives using `move_exchange!`.
"""
function localSearch_intensification_VNS_LPRC_exchange!(solution::Solution, instance::Instance)
    # useful variable
    b0 = instance.nb_late_prec_day+1

    list = Array{Int, 1}()
    improved = true
    while improved
        improved = false
        critical_cars = find_critical_cars(solution, instance, 2)
        for index_car_a in critical_cars
            best_delta = -1 # < 0 to avoid to select delta = 0 if there is no improvment (avoid cycle)
            empty!(list)
            for index_car_b in b0:instance.nb_cars
                if (index_car_a != index_car_b)
                    delta = weighted_sum(cost_move_exchange(solution, index_car_a, index_car_b, instance, 2))
                    if delta < best_delta
                        list = [index_car_b]
                        best_delta = delta
                    elseif delta == best_delta
                        push!(list, index_car_b)
                    end
                end
            end
            if !isempty(list)
                index_car_b = rand(list)
                move_exchange!(solution, index_car_a, index_car_b, instance)
                improved = true
            end
        end
    end

    return solution
end

"""
    localSearch_intensification_VNS_LPRC_insertion!(solution::Solution, instance::Instance)

Optimizes the weighted sum of first and second objectives using `move_insertion!`.
"""
function localSearch_intensification_VNS_LPRC_insertion!(solution::Solution, instance::Instance)
    # useful variable
    b0 = instance.nb_late_prec_day+1

    improved = true
    while improved
        improved = false
        critical_cars = find_critical_cars(solution, instance, 2)
        for index_car in critical_cars
            best_delta = -1 # < 0 to avoid to select delta = 0 if there is no improvment (avoid cycle)
            best_positions = Vector{Int}()
            matrix_deltas = cost_move_insertion(solution, index_car, instance, 2)
            for position in b0:instance.nb_cars
                delta = weighted_sum(matrix_deltas[position, :])
                if delta < best_delta
                    best_positions = Vector{Int}([position])
                    best_delta = delta
                elseif delta == best_delta
                    push!(best_positions, position)
                end
            end

            if !isempty(best_positions)
                index_insert = rand(best_positions)
                move_insertion!(solution, index_car, index_insert, instance)
                improved = true
            end
        end
    end
    return solution
end

"""
    intensification_VNS_LPRC!(solution::Solution, instance::Instance)

Calls both intensification.
"""
function intensification_VNS_LPRC!(solution::Solution, instance::Instance)
    localSearch_intensification_VNS_LPRC_insertion!(solution, instance)
    localSearch_intensification_VNS_LPRC_exchange!(solution, instance)
    return solution
end

"""
    is_better_VNS_LPRC(solution_1::Solution, solution_2::Solution, instance::Instance)

Returns `true` if the weighted sum of `solution_1`'s objective value is better
than the weighted sum of `solution_2`'s objective value and if the HPRC value of
`solution_1` is better or equal than the HPRC value of `solution_2`.
Returns `false` otherwise.
"""
function is_better_VNS_LPRC(solution_1::Solution, solution_2::Solution, instance::Instance)
    solution_1_cost = cost(solution_1, instance, 2)
    solution_2_cost = cost(solution_2, instance, 2)

    cost_better = weighted_sum(solution_1_cost) <= weighted_sum(solution_2_cost)
    HPRC_not_worse = solution_1_cost[1] <= solution_2_cost[1]

    return cost_better && HPRC_not_worse
end

"""
    is_strictly_better_VNS_LPRC(solution_1::Solution, solution_2::Solution, instance::Instance)

Returns `true` if the weighted sum of `solution_1`'s objective value is better
than the weighted sum of `solution_2`'s objective value and if the HPRC value of
`solution_1` is better or equal than the HPRC value of `solution_2`.
Returns `false` otherwise.
"""
function is_strictly_better_VNS_LPRC(solution_1::Solution, solution_2::Solution, instance::Instance)
    solution_1_cost = cost(solution_1, instance, 2)
    solution_2_cost = cost(solution_2, instance, 2)

    cost_better = weighted_sum(solution_1_cost) < weighted_sum(solution_2_cost)
    HPRC_not_worse = solution_1_cost[1] <= solution_2_cost[1]

    return cost_better && HPRC_not_worse
end

"""
    VNS_LPRC(solution_init::Solution, instance::Instance, start_time::UInt)

Optimizes the weighted sum of first and second objectives.
"""
function VNS_LPRC(solution_init::Solution, instance::Instance, start_time::UInt)
    # p = 0 implies insertion move and p = 1 implies exchange move as stated
    # in section 6.1. Note that section 6.5 states the opposite.
    _bitarray = BitArray{1}([false, true, false])

    # variables of the algorithm
    solution = deepcopy(solution_init)
    solution_best = deepcopy(solution_init)
    k_min = (VNS_LPRC_MIN_INSERT, VNS_LPRC_MIN_EXCHANGE)
    k_max = (VNS_LPRC_MAX_INSERT, VNS_LPRC_MAX_EXCHANGE)
    p = 0
    k = k_min[p+1]
    nb_intens_not_better = 0
    while (nb_intens_not_better < VNS_LPRC_MAX_NON_IMPROVEMENT
          && (96/100) * TIME_LIMIT > (time_ns() - start_time) / 1.0e9
          && cost(solution, instance, _bitarray) != 0)
        while (k <= k_max[p+1]
              && (96/100) * TIME_LIMIT > (time_ns() - start_time) / 1.0e9)
            neighbor = perturbation_VNS_LPRC(solution, p, k, instance)
            localSearch_VNS_LPRC!(neighbor, p == 1, instance)
            if is_strictly_better_VNS_LPRC(neighbor, solution, instance)
                solution = deepcopy(neighbor)
                k = k_min[p+1]
                nb_intens_not_better = 0
            else
                k = k + 1
            end
            if is_better_VNS_LPRC(solution, solution_best, instance)
                solution_best = deepcopy(solution)
            end
        end
        intensification_VNS_LPRC!(solution, instance)
        nb_intens_not_better += 1

        p = 1 - p
        k = k_min[p+1]
    end

    return solution_best
end
