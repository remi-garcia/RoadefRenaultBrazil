#-------------------------------------------------------------------------------
# File: vns_mo.jl
# Description: This files contains all function that are used in VNS MO.
# Date: December 11, 2019
# Author: Jonathan Fontaine, Killian Fretaud, Rémi Garcia,
#         Boualem Lamraoui, Benoît Le Badezet, Benoit Loger
#-------------------------------------------------------------------------------

"""
    perturbation_VNS_MO_exchange(solution::Solution, k::Int, instance::Instance)

Returns a new solution obtain by `k` random exchanges between cars. Exchanged
cars must have the same color.
"""
function perturbation_VNS_MO_exchange!(solution::Solution, k::Int, instance::Instance)
    b0 = instance.nb_late_prec_day+1
    # Array that contain only key defining more than one car
    valid_key_color = Array{Int,1}(undef, 0)
    for group in instance.same_color
        if length(group.second) >= 2
            push!(valid_key_color, group.first)
        end
    end

    for _ in 1:k
        same_color_array = instance.same_color[rand(valid_key_color)]
        car_pos_a = rand(same_color_array)
        car_pos_b = rand(same_color_array)
        # Cannot be the same
        while car_pos_a == car_pos_b
            car_pos_b = rand(same_color_array)
        end
        solution.sequence[car_pos_a], solution.sequence[car_pos_b] = solution.sequence[car_pos_b], solution.sequence[car_pos_a]
        if is_sequence_valid(solution.sequence, instance.nb_cars, instance)
            solution.sequence[car_pos_a], solution.sequence[car_pos_b] = solution.sequence[car_pos_b], solution.sequence[car_pos_a]
            move_exchange!(solution, car_pos_a, car_pos_b, instance)
        else
            solution.sequence[car_pos_a], solution.sequence[car_pos_b] = solution.sequence[car_pos_b], solution.sequence[car_pos_a]
        end
    end

    return solution
end

"""
    perturbation_VNS_MO_insertion(solution::Solution, k::Int,
                                   critical_cars::Array{Int, 1},
                                   instance::Instance)

Delete k vehicles from the sequence and add them back in the sequence according
to a greedy criterion.
"""
function perturbation_VNS_MO_insertion!(solution::Solution, k::Int,
                                        critical_cars::Array{Int, 1},
                                        instance::Instance)
    remove!(solution, instance, k, critical_cars)
    for i in 1:k
        greedy_add!(solution, instance, instance.nb_cars, 3, true)
    end
    @assert instance.nb_cars == solution.length
    return solution
end

"""
    perturbation_VNS_MO(solution_init::Solution, p::Int, k::Int, instance::Instance)

Calls both perturbations and return a new solution. This function does not
modify the solution given in parameters.
"""
function perturbation_VNS_MO(solution_init::Solution, p::Int, k::Int, instance::Instance)
    solution = deepcopy(solution_init)
    if p == 1
        perturbation_VNS_MO_exchange!(solution, k, instance)
    else
        critical_cars = find_critical_cars(solution, instance, 2)
        k = min(k, length(critical_cars))
        perturbation_VNS_MO_insertion!(solution, k, critical_cars, instance)
    end

    return solution
end

"""
    local_search_intensification_VNS_MO_exchange!(solution::Solution, instance::Instance, max_possible_delta::Int,
                                                  time_for_next_solution, start_time::UInt)

Optimizes the weighted sum of three objectives using `move_exchange!`.
"""
function local_search_intensification_VNS_MO_exchange!(solution::Solution, instance::Instance, max_possible_delta::Int,
                                                       time_for_next_solution, start_time::UInt)
    # useful variable
    b0 = instance.nb_late_prec_day+1
    n = instance.nb_cars

    improved = true
    sequence = copy(solution.sequence)
    while improved && time_for_next_solution > (time_ns() - start_time) / 1.0e9
        improved = false
        critical_cars = find_critical_cars(solution, instance, 2)
        for index_car_a in critical_cars
            best_delta = 0
            best_positions = Array{Int, 1}()
            for index_car_b in b0:instance.nb_cars
                if index_car_a != index_car_b
                    sequence[index_car_a], sequence[index_car_b] = sequence[index_car_b], sequence[index_car_a]
                    if is_sequence_valid(sequence, instance.nb_cars, instance)
                        cost_move = cost_move_exchange(solution, index_car_a, index_car_b, instance, 3)
                        delta = weighted_sum(cost_move, 2)
                        if cost_move[3] < max_possible_delta
                            if delta < best_delta
                                best_positions = Array{Int, 1}([index_car_b])
                                best_delta = delta
                            elseif delta == best_delta
                                push!(best_positions, index_car_b)
                            end
                        end
                    end
                    sequence[index_car_a], sequence[index_car_b] = sequence[index_car_b], sequence[index_car_a]
                end
            end
            if !isempty(best_positions)
                index_car_b = rand(best_positions)
                max_possible_delta -= cost_move_exchange(solution, index_car_a, index_car_b, instance, BitArray{1}([false, false, true]))[3]
                move_exchange!(solution, index_car_a, index_car_b, instance)
                sequence[index_car_a], sequence[index_car_b] = sequence[index_car_b], sequence[index_car_a]
                if best_delta < 0
                    improved = true
                end
            end
        end
    end

    return solution
end

"""
    local_search_intensification_VNS_MO_insertion!(solution::Solution, instance::Instance, max_possible_delta::Int,
                                                   time_for_next_solution, start_time::UInt)

Optimizes the weighted sum of three objectives using `move_insertion!`.
"""
function local_search_intensification_VNS_MO_insertion!(solution::Solution, instance::Instance, max_possible_delta::Int,
                                                        time_for_next_solution, start_time::UInt)
    # useful variable
    b0 = instance.nb_late_prec_day+1
    improved = true
    while improved && time_for_next_solution > (time_ns() - start_time) / 1.0e9
        improved = false
        for index_car in b0:instance.nb_cars
            best_delta = 0
            best_positions = Array{Int, 1}()
            matrix_deltas = cost_move_insertion(solution, index_car, instance, 3)
            penalize_costs!(matrix_deltas, index_car, solution, instance)
            for position in b0:instance.nb_cars
                if position != index_car
                    if matrix_deltas[position, 3] < max_possible_delta
                        delta = weighted_sum(matrix_deltas[position, :])
                        if delta < best_delta
                            best_positions = Array{Int, 1}([position])
                            best_delta = delta
                        elseif delta == best_delta
                            push!(best_positions, position)
                        end
                    end
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
    intensification_VNS_MO!(solution::Solution, instance::Instance)

Calls both intensification.
"""
function intensification_VNS_MO!(solution::Solution, instance::Instance, max_possible_delta::Int, time_for_next_solution, cost_MO_solution_init::Int, start_time::UInt)
    local_search_intensification_VNS_MO_insertion!(solution, instance, max_possible_delta, time_for_next_solution, start_time)
    local_search_intensification_VNS_MO_exchange!(solution, instance, max_possible_delta-(cost(solution, instance, 3)[3]-cost_MO_solution_init), time_for_next_solution, start_time)
    return solution
end

"""

"""
function local_search_VNS_MO!(solution::Solution, instance::Instance, time_for_next_solution, start_time::UInt)
    b0 = instance.nb_late_prec_day+1

    improved = true
    while improved && time_for_next_solution > (time_ns() - start_time) / 1.0e9
        improved = false
        for index_car_a in b0:instance.nb_cars
            best_delta = 0
            best_positions = Array{Int, 1}()
            color_value = instance.color_code[solution.sequence[index_car_a]]
            for index_car_b in instance.same_color[color_value]
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

"""
function VNS_MO(solutions_init::Array{Solution, 1}, instance::Instance, start_time::UInt)
    solutions = deepcopy(solutions_init)

    while TIME_LIMIT > (time_ns() - start_time) / 1.0e9 && solutions[1].saved_costs[3] > solutions[end].saved_costs[3]
        max_possible_delta = 8
        time_left = TIME_LIMIT - ((time_ns() - start_time) / 1.0e9)
        time_for_solution = min(time_left, time_left*max_possible_delta / (10*(solutions[1].saved_costs[3] - solutions[end].saved_costs[3])))
        time_for_next_solution = time_for_solution + ((time_ns() - start_time) / 1.0e9)
        solution = deepcopy(solutions[end])
        solution.M1 = zeros(Int, instance.nb_HPRC + instance.nb_LPRC, instance.nb_cars)
        solution.M2 = zeros(Int, instance.nb_HPRC + instance.nb_LPRC, instance.nb_cars)
        solution.M3 = zeros(Int, instance.nb_HPRC + instance.nb_LPRC, instance.nb_cars)
        update_matrices!(solution, instance)
        initialize_batches!(solution, instance)
        improved = false
        p = 1
        k = VNS_MO_MINMAX[p+1][1]
        costs_solution = collect(solution.saved_costs)
        cost_solution_init = weighted_sum(costs_solution, 2)
        cost_solution = cost_solution_init
        cost_MO_solution_init = costs_solution[3]
        cost_MO_solution = cost_MO_solution_init
        while (time_for_next_solution > (time_ns() - start_time) / 1.0e9 || !improved) && TIME_LIMIT > (time_ns() - start_time) / 1.0e9
            while !improved && (k <= VNS_MO_MINMAX[p+1][2]) && time_for_next_solution > (time_ns() - start_time) / 1.0e9
                solution_perturbation = perturbation_VNS_MO(solution, p, k, instance)
                costs_perturbation = cost(solution_perturbation, instance, 3)
                if (costs_perturbation[3] - cost_MO_solution_init) > max_possible_delta
                    solution_perturbation = deepcopy(solution)
                end
                local_search_VNS_MO!(solution_perturbation, instance, time_for_next_solution, start_time)
                costs_perturbation = cost(solution_perturbation, instance, 3)
                cost_solution_perturbation = weighted_sum(costs_perturbation, 2)
                if cost_solution_perturbation < cost_solution && (costs_perturbation[3] - cost_MO_solution_init) <= max_possible_delta
                    k = VNS_MO_MINMAX[p+1][1]
                else
                    k += 1
                end
                if cost_solution_perturbation <= cost_solution && (costs_perturbation[3] - cost_MO_solution_init) <= max_possible_delta
                    solution = deepcopy(solution_perturbation)
                    costs_solution = cost(solution, instance, 3)
                    cost_solution = copy(cost_solution_perturbation)
                    cost_MO_solution = costs_solution[3]
                end
                if !improved && cost_solution < cost_solution_init && (costs_solution[3] - cost_MO_solution_init) <= max_possible_delta
                    improved = true
                end
            end
            if !improved && cost_solution < cost_solution_init && (costs_solution[3] - cost_MO_solution_init) <= max_possible_delta
                improved = true
            end
            if time_for_next_solution < (time_ns() - start_time) / 1.0e9 && !improved
                time_for_next_solution = min(time_left, (time_left*max_possible_delta / (10*(solutions[1].saved_costs[3] - solutions[end].saved_costs[3])))) + ((time_ns() - start_time) / 1.0e9)
                intensification_VNS_MO!(solution, instance, max_possible_delta-(cost_MO_solution-cost_MO_solution_init), time_for_next_solution, cost_MO_solution_init, start_time)
            end
            costs_solution = cost(solution, instance, 3)
            cost_solution = weighted_sum(costs_solution, 2)
            cost_MO_solution = costs_solution[3]
            p = 1 - p
            k = VNS_MO_MINMAX[p+1][1]
            if !improved && cost_solution < cost_solution_init && (costs_solution[3] - cost_MO_solution_init) <= max_possible_delta
                improved = true
            end
            if time_for_next_solution < (time_ns() - start_time) / 1.0e9 && !improved
                max_possible_delta += 8
                time_for_next_solution = min(time_left, (time_left*max_possible_delta / (10*(solutions[1].saved_costs[3] - solutions[end].saved_costs[3]))) + ((time_ns() - start_time) / 1.0e9))
            end
        end

        costs_solution = cost(solution, instance, 3)
        solution.saved_costs = (costs_solution[1], costs_solution[2], costs_solution[3])
        solution.M1 = nothing
        solution.M2 = nothing
        solution.M3 = nothing
        solution.colors = nothing
        push!(solutions, solution)
        println(costs_solution)
    end

    return solutions
end
