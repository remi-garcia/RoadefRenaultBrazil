#-------------------------------------------------------------------------------
# File: vns_lprc.jl
# Description: This files contains all functions that are used in VNS_LPRC.
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
        greedy_add!(solution, instance, instance.nb_cars, 2)
    end
    return solution
end

"""
    perturbation_VNS_LPRC_exchange!(solution::Solution, k::Int, instance::Instance)

Randomly applies k exchange between cars that are involved in the same
constraints.
"""
function perturbation_VNS_LPRC_exchange!(solution::Solution, k::Int, instance::Instance)
    # Array that contain only key defining more than one car
    valid_key_HPRC = Array{Int,1}(undef, 0)
    # for key in keys(instance.same_HPRC)
    #   if length(instance.same_HPRC[key]) >= 2
    #       push!(valid_key_HPRC, key)
    # OR:
    for group in instance.same_HPRC
        if length(group.second) >= 2
            push!(valid_key_HPRC, group.first)
        end
    end

    for _ in 1:k
        same_HPRC_array = instance.same_HPRC[rand(valid_key_HPRC)]
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
    perturbation_VNS_LPRC(solution_init::Solution, p::Int, k::Int, instance::Instance)

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
    local_search_VNS_LPRC!(solution::Solution, perturbation_exchange::Bool, instance::Instance)

Optimizes the weighted sum of first and second objectives. When
`perturbation_exchange` is `true` this function does not degrade the first
objective.
"""
function local_search_VNS_LPRC!(solution::Solution, perturbation_exchange::Bool, instance::Instance)
    # useful variable
    b0 = instance.nb_late_prec_day+1

    improved = true
    while improved
        improved = false
        critical_cars = find_critical_cars(solution, instance, 2)
        for index_car_a in critical_cars
            best_delta = 0
            best_positions = Array{Int, 1}()
            hprc_value = instance.HPRC_keys[solution.sequence[index_car_a]]
            for index_car_b in b0:instance.nb_cars
                if !perturbation_exchange || (index_car_a != index_car_b && index_car_b in instance.same_HPRC[hprc_value])
                    delta = weighted_sum(cost_move_exchange(solution, index_car_a, index_car_b, instance, 2))
                    if delta < best_delta
                        best_positions = Array{Int, 1}([index_car_b])
                        best_delta = delta
                    elseif delta == best_delta
                        push!(best_positions, index_car_b)
                    end
                end
            end
            if !isempty(best_positions)
                index_car_b = rand(best_positions)
                move_exchange!(solution, index_car_a, index_car_b, instance)
                if best_delta < 0
                    improved = true
                end
            end
        end
    end

    return solution
end

"""
    local_search_intensification_VNS_LPRC_exchange!(solution::Solution, instance::Instance)

Optimizes the weighted sum of first and second objectives using `move_exchange!`.
"""
function local_search_intensification_VNS_LPRC_exchange!(solution::Solution, instance::Instance)
    # useful variable
    b0 = instance.nb_late_prec_day+1

    improved = true
    while improved
        improved = false
        critical_cars = find_critical_cars(solution, instance, 2)
        for index_car_a in critical_cars
            best_delta = 0
            best_positions = Array{Int, 1}()
            for index_car_b in b0:instance.nb_cars
                if index_car_a != index_car_b
                    delta = weighted_sum(cost_move_exchange(solution, index_car_a, index_car_b, instance, 2))
                    if delta < best_delta
                        best_positions = Array{Int, 1}([index_car_b])
                        best_delta = delta
                    elseif delta == best_delta
                        push!(best_positions, index_car_b)
                    end
                end
            end
            if !isempty(best_positions)
                index_car_b = rand(best_positions)
                move_exchange!(solution, index_car_a, index_car_b, instance)
                if best_delta < 0
                    improved = true
                end
            end
        end
    end

    return solution
end

"""
    local_search_intensification_VNS_LPRC_insertion!(solution::Solution, instance::Instance)

Optimizes the weighted sum of first and second objectives using `move_insertion!`.
"""
function local_search_intensification_VNS_LPRC_insertion!(solution::Solution, instance::Instance)
    # useful variable
    b0 = instance.nb_late_prec_day+1

    improved = true
    while improved
        improved = false
        critical_cars = find_critical_cars(solution, instance, 2)
        for index_car in critical_cars
            best_delta = 0
            best_positions = Array{Int, 1}()
            matrix_deltas = cost_move_insertion(solution, index_car, instance, 2)
            for position in b0:instance.nb_cars
                delta = weighted_sum(matrix_deltas[position, :])
                if delta < best_delta
                    best_positions = Array{Int, 1}([position])
                    best_delta = delta
                elseif delta == best_delta
                    push!(best_positions, position)
                end
            end

            if !isempty(best_positions)
                index_insert = rand(best_positions)
                move_insertion!(solution, index_car, index_insert, instance)
                if best_delta < 0
                    improved = true
                end
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
    local_search_intensification_VNS_LPRC_insertion!(solution, instance)
    local_search_intensification_VNS_LPRC_exchange!(solution, instance)
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
    solution_best = deepcopy(solution_init)
    k_min = (VNS_LPRC_MIN_INSERT, VNS_LPRC_MIN_EXCHANGE)
    k_max = (VNS_LPRC_MAX_INSERT, VNS_LPRC_MAX_EXCHANGE)
    p = 0
    k = k_min[p+1]
    nb_intens_not_better = 0
    vector_zero = zeros(Int, 3)
    while (nb_intens_not_better < VNS_LPRC_MAX_NON_IMPROVEMENT
          && TIME_PART_VNS_LPRC * TIME_LIMIT > (time_ns() - start_time) / 1.0e9
          && cost(solution_best, instance, _bitarray) != vector_zero)
        while (k <= k_max[p+1]
              && TIME_PART_VNS_LPRC * TIME_LIMIT > (time_ns() - start_time) / 1.0e9)
            neighbor = perturbation_VNS_LPRC(solution_best, p, k, instance)
            local_search_VNS_LPRC!(neighbor, p == 1, instance)
            if is_strictly_better_VNS_LPRC(neighbor, solution_best, instance)
                k = k_min[p+1]
                nb_intens_not_better = 0
            else
                k = k + 1
            end
            if is_better_VNS_LPRC(neighbor, solution_best, instance)
                solution_best = deepcopy(neighbor)
            end
        end
        intensification_VNS_LPRC!(solution_best, instance)
        nb_intens_not_better += 1

        p = 1 - p
        k = k_min[p+1]
    end

    return solution_best
end
