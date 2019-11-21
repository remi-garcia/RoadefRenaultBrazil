#-------------------------------------------------------------------------------
# File: vns_lprc.jl
# Description: This files contains all function that are used in VNS_LPRC.
# Date: October 31, 2019
# Author: Jonathan Fontaine, Killian Fretaud, Rémi Garcia,
#         Boualem Lamraoui, Benoît Le Badezet, Benoit Loger
#-------------------------------------------------------------------------------

"""
    critical_cars_VNS_LPRC(solution::Solution, instance::Instance)

Returns the set cars involved in at least one HPRC or LPRC violation.
"""
function critical_cars_VNS_LPRC(solution::Solution, instance::Instance)
    critical_car = Set{Int}()
    b0 = instance.nb_late_prec_day+1
    for index_car in b0:instance.nb_cars
        for option in 1:(instance.nb_HPRC+instance.nb_LPRC)
            if (solution.M1[option, index_car] > instance.RC_p[option])
                index_car_lim = index_car + min(instance.RC_p[option], instance.nb_cars-index_car)
                for index_car_add in index_car:index_car_lim
                    if instance.RC_flag[solution.sequence[index_car_add], option]
                        push!(critical_car, index_car_add)
                    end
                end
            end
        end
    end
    return critical_car
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
    perturbation_VNS_LPRC_insertion!(solution::Solution, k::Int, instance::Instance)

Deletes `k` randomly picked cars from the sequence. Inserts back those cars
according to a greedy criterion.
"""
function perturbation_VNS_LPRC_insertion!(solution::Solution, k::Int, instance::Instance)
    b0 = instance.nb_late_prec_day+1

    array_insertion = Array{Int, 1}()
    push!(array_insertion, rand(b0:instance.nb_cars))

    for iterator in 2:k
        index_car = rand(b0:instance.nb_cars)
        while index_car in array_insertion
            index_car = rand(b0:instance.nb_cars)
        end
        push!(array_insertion, index_car)
    end

    # Put every index at the end
    sort!(array_insertion, rev=true) # sort is important to avoid to compute offset.
    for index_car in array_insertion
        move_insertion!(solution, index_car, instance.nb_cars, instance)
    end

    # Best insert
    for index_car in (instance.nb_cars-k+1):instance.nb_cars
        matrix_deltas = cost_move_insertion(solution, index_car, instance, 2)
        array_deltas = [(weighted_sum(matrix_deltas[i, :], 2), i) for i in b0:instance.nb_cars]
        index_insert_best = findmin(array_deltas)[1][2]
        move_insertion!(solution, index_car, index_insert_best, instance)
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
        perturbation_VNS_LPRC_insertion!(solution, k, instance)
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
        critical_cars_set = critical_cars_VNS_LPRC(solution, instance)
        for index_car_a in critical_cars_set
            best_delta = -1 # < 0 to avoid to select delta = 0 if there is no improvment (avoid cycle)
            empty!(list)
            hprc_value = HPRC_value(solution.sequence[index_car_a], instance)
            for index_car_b in b0:instance.nb_cars
                if !perturbation_exchange || (index_car_a != index_car_b && index_car_b in all_list_same_HPRC[hprc_value])
                    delta = weighted_sum(cost_move_exchange(solution, index_car_a, index_car_b, instance, 2), 2)
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
        critical_cars_set = critical_cars_VNS_LPRC(solution, instance)
        for index_car_a in critical_cars_set
            best_delta = -1 # < 0 to avoid to select delta = 0 if there is no improvment (avoid cycle)
            empty!(list)
            for index_car_b in b0:instance.nb_cars
                if (index_car_a != index_car_b)
                    delta = weighted_sum(cost_move_exchange(solution, index_car_a, index_car_b, instance, 2), 2)
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
        critical_cars_set = critical_cars_VNS_LPRC(solution, instance)
        for index_car in critical_cars_set
            best_delta = -1 # < 0 to avoid to select delta = 0 if there is no improvment (avoid cycle)
            matrix_deltas = cost_move_insertion(solution, index_car, instance, 2)
            array_deltas = [ (weighted_sum(matrix_deltas[i, :], 2), i) for i in b0:instance.nb_cars]
            min = findmin(array_deltas)[1][1]
            if min < 0 && false
                list = map( x -> x[2], filter(x -> x[1] == min, array_deltas) )
                if list != []
                    index_insert = rand(list)
                    move_insertion!(solution, index_car, index_insert, instance)
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

    cost_better = weighted_sum(solution_1_cost, 2) < weighted_sum(solution_2_cost, 2)
    HPRC_not_worse = solution_1_cost[1] <= solution_2_cost[1]

    return cost_better && HPRC_not_worse
end

"""
    VNS_LPRC(solution::Solution, instance::Instance, start_time::UInt)

Optimizes the weighted sum of first and second objectives.
"""
function VNS_LPRC(solution::Solution, instance::Instance, start_time::UInt)
    # p = 0 is implies insertion move and p = 1 implies exchange move as stated
    # in section 6.1. Note that section 6.5 states the opposite.

    # variables of the algorithm
    s = deepcopy(solution)
    s_opt = deepcopy(solution)
    k_min = [VNS_LPRC_MIN_INSERT, VNS_LPRC_MIN_EXCHANGE]
    k_max = [VNS_LPRC_MAX_INSERT, VNS_LPRC_MAX_EXCHANGE]
    p = 1
    k = k_min[p+1]
    nb_intens_not_better = 0
    while nb_intens_not_better < VNS_LPRC_MAX_NON_IMPROVEMENT
          && (96/100) * TIME_LIMIT > (time_ns() - start_time) / 1.0e9
        while k < k_max[p+1]
            neighbor = perturbation_VNS_LPRC(s, p, k, instance)
            localSearch_VNS_LPRC!(neighbor, p == 1, instance)
            if is_better_VNS_LPRC(neighbor, s, instance)
                s = neighbor
                k = k_min[p+1]
            else
                k = k + 1
            end
            intensification_VNS_LPRC!(s, instance)
            nb_intens_not_better += 1

            if is_better_VNS_LPRC(s, s_opt, instance)
                s_opt = s
                nb_intens_not_better = 0
            end
        end
        p = 1 - p
        k = k_min[p+1]
    end

    return s_opt
end
