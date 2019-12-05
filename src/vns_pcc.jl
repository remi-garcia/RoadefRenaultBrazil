#-------------------------------------------------------------------------------
# File: vns_pcc.jl
# Description: This files contains all function that are used in VNS_PCC.
# Date: November 03, 2019
# Author: Jonathan Fontaine, Killian Fretaud, Rémi Garcia,
#         Boualem Lamraoui, Benoît Le Badezet, Benoit Loger
#-------------------------------------------------------------------------------

"""
    perturbation_VNS_PCC_exchange(solution::Solution, k::Int, instance::Instance)

Returns a new solution obtain by `k` random exchanges between cars. Exchanged
cars must have the same HPRC constraints.
"""
function perturbation_VNS_PCC_exchange!(solution::Solution, k::Int, instance::Instance)
    HPRC_cars_groups = Dict{Int, Array{Int, 1}}()
    b0 = instance.nb_late_prec_day+1
    for car_pos in b0:instance.nb_cars
        car_HPRC_value = HPRC_value(solution.sequence[car_pos], instance)
        if !haskey(HPRC_cars_groups, car_HPRC_value)
            HPRC_cars_groups[car_HPRC_value] = [car_pos]
        else
            push!(HPRC_cars_groups[car_HPRC_value], car_pos)
        end
    end
    filter!(x -> length(x.second) >= 2, HPRC_cars_groups)

    sequence = solution.sequence
    for _ in 1:k
        HPRC_group = rand(keys(HPRC_cars_groups))
        car_pos_a = rand(HPRC_cars_groups[HPRC_group])
        car_pos_b = rand(HPRC_cars_groups[HPRC_group])
        # Must have the same options
        while car_pos_a == car_pos_b
            car_pos_b = rand(HPRC_cars_groups[HPRC_group])
        end
        sequence[car_pos_a], sequence[car_pos_b] = sequence[car_pos_b], sequence[car_pos_a]
        if is_sequence_valid(sequence, instance.nb_cars, instance)
            move_exchange!(solution, car_pos_a, car_pos_b, instance)
        else
            sequence[car_pos_a], sequence[car_pos_b] = sequence[car_pos_b], sequence[car_pos_a]
        end
    end

    return solution
end

"""
    perturbation_VNS_PCC_insertion(solution::Solution, k::Int,
                                   critical_cars::Array{Int, 1},
                                   instance::Instance)

Delete k vehicles from the sequence and add them back in the sequence according
to a greedy criterion.
"""
function perturbation_VNS_PCC_insertion!(solution::Solution, k::Int,
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
    perturbation_VNS_PCC(solution_init::Solution, p::Int, k::Int, instance::Instance)

Calls both perturbations and return a new solution. This function does not
modify the solution given in parameters.
"""
function perturbation_VNS_PCC(solution_init::Solution, p::Int, k::Int, instance::Instance)
    solution = deepcopy(solution_init)
    if p == 1
        perturbation_VNS_PCC_exchange!(solution, k, instance)
    else
        critical_cars = find_critical_cars(solution, instance, 2)
        k = min(k, length(critical_cars))
        perturbation_VNS_PCC_insertion!(solution, k, critical_cars, instance)
    end

    return solution
end

"""
    local_search_intensification_VNS_PCC_exchange!(solution::Solution, instance::Instance)

Optimizes the weighted sum of three objectives using `move_exchange!`.
"""
function local_search_intensification_VNS_PCC_exchange!(solution::Solution, instance::Instance, start_time::UInt)
    # useful variable
    b0 = instance.nb_late_prec_day+1
    n = instance.nb_cars

    improved = true
    sequence = copy(solution.sequence)
    while improved && TIME_LIMIT > (time_ns() - start_time) / 1.0e9
        improved = false
        critical_cars = find_critical_cars(solution, instance, 2)
        for index_car_a in critical_cars
            best_delta = 0
            best_positions = Array{Int, 1}()
            for index_car_b in b0:instance.nb_cars
                if index_car_a != index_car_b
                    sequence[index_car_a], sequence[index_car_b] = sequence[index_car_b], sequence[index_car_a]
                    if is_sequence_valid(sequence, instance.nb_cars, instance)
                        delta = weighted_sum(cost_move_exchange(solution, index_car_a, index_car_b, instance, 3))
                        if delta < best_delta
                            best_positions = Array{Int, 1}([index_car_b])
                            best_delta = delta
                        elseif delta == best_delta
                            push!(best_positions, index_car_b)
                        end
                    end
                    sequence[index_car_a], sequence[index_car_b] = sequence[index_car_b], sequence[index_car_a]
                end
            end
            if !isempty(best_positions)
                index_car_b = rand(best_positions)
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
    local_search_intensification_VNS_PCC_insertion!(solution::Solution, instance::Instance)

Optimizes the weighted sum of three objectives using `move_insertion!`.
"""
function local_search_intensification_VNS_PCC_insertion!(solution::Solution, instance::Instance, start_time::UInt)
    # useful variable
    b0 = instance.nb_late_prec_day+1

    improved = true
    while improved && TIME_LIMIT > (time_ns() - start_time) / 1.0e9
        improved = false
        for index_car in b0:instance.nb_cars
            best_delta = 0
            best_positions = Array{Int, 1}()
            matrix_deltas = cost_move_insertion(solution, index_car, instance, 3)
            penalize_costs!(matrix_deltas, index_car, solution, instance)
            for position in b0:instance.nb_cars
                if position != index_car
                    delta = weighted_sum(matrix_deltas[position, :])
                    if delta < best_delta
                        best_positions = Array{Int, 1}([position])
                        best_delta = delta
                    elseif delta == best_delta
                        push!(best_positions, position)
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
    intensification_VNS_PCC!(solution::Solution, instance::Instance)

Calls both intensification.
"""
function intensification_VNS_PCC!(solution::Solution, instance::Instance, start_time::UInt)
    local_search_intensification_VNS_PCC_insertion!(solution, instance, start_time)
    local_search_intensification_VNS_PCC_exchange!(solution, instance, start_time)
    return solution
end

"""

"""
function local_search_VNS_PCC!(solution::Solution, instance::Instance, start_time::UInt)
    b0 = instance.nb_late_prec_day+1
    all_list_same_HPRC = Dict{Int, Array{Int, 1}}()
    for index_car in b0:instance.nb_cars
        key_HPRC = HPRC_value(solution.sequence[index_car], instance)
        if !(key_HPRC in keys(all_list_same_HPRC))
            all_list_same_HPRC[key_HPRC] = Array{Int, 1}()
        end
        push!(all_list_same_HPRC[key_HPRC], index_car)
    end

    improved = true
    sequence = copy(solution.sequence)
    while improved && TIME_LIMIT > (time_ns() - start_time) / 1.0e9
        improved = false
        for index_car_a in b0:instance.nb_cars
            best_delta = 0
            best_positions = Array{Int, 1}()
            hprc_value = HPRC_value(solution.sequence[index_car_a], instance)
            for index_car_b in all_list_same_HPRC[hprc_value]
                if index_car_a != index_car_b
                    sequence[index_car_a], sequence[index_car_b] = sequence[index_car_b], sequence[index_car_a]
                    if is_sequence_valid(sequence, instance.nb_cars, instance)
                        delta = weighted_sum(cost_move_exchange(solution, index_car_a, index_car_b, instance, 3))
                        if delta < best_delta
                            best_positions = Array{Int, 1}([index_car_b])
                            best_delta = delta
                        elseif delta == best_delta
                            push!(best_positions, index_car_b)
                        end
                    end
                    sequence[index_car_a], sequence[index_car_b] = sequence[index_car_b], sequence[index_car_a]
                end
            end
            if !isempty(best_positions)
                index_car_b = rand(best_positions)
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

"""
function VNS_PCC(solution_init::Solution, instance::Instance, start_time::UInt)
    solution = deepcopy(solution_init)
    p = 1
    k = VNS_PCC_MINMAX[p+1][1]
    costs_solution = cost(solution, instance, 3)
    cost_solution = weighted_sum(costs_solution)
    cost_HPRC_solution = costs_solution[1]
    while TIME_LIMIT > (time_ns() - start_time) / 1.0e9
        while (k <= VNS_PCC_MINMAX[p+1][2]) && (TIME_LIMIT > (time_ns() - start_time) / 1.0e9)
            solution_perturbation = perturbation_VNS_PCC(solution, p, k, instance)
            if cost_HPRC_solution < cost(solution_perturbation, instance, 1)[1]
                solution_perturbation = deepcopy(solution)
            end
            local_search_VNS_PCC!(solution_perturbation, instance, start_time)
            cost_solution_perturbation = weighted_sum(solution_perturbation, instance)
            if cost_solution_perturbation < cost_solution
                k = VNS_PCC_MINMAX[p+1][1]
            else
                k += 1
            end
            if cost_solution_perturbation <= cost_solution
                solution = deepcopy(solution_perturbation)
                costs_solution = cost(solution, instance, 3)
                cost_solution = copy(cost_solution_perturbation)
                cost_HPRC_solution = costs_solution[1]
            end
        end
        intensification_VNS_PCC!(solution, instance, start_time)
        costs_solution = cost(solution, instance, 3)
        cost_solution = weighted_sum(costs_solution)
        cost_HPRC_solution = costs_solution[1]
        p = 1 - p
        k = VNS_PCC_MINMAX[p+1][1]
    end

    return solution
end
