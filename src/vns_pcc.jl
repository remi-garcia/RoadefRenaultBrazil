#-------------------------------------------------------------------------------
# File: vns_pcc.jl
# Description: This files contains all function that are used in VNS_PCC.
# Date: November 03, 2019
# Author: Jonathan Fontaine, Killian Fretaud, Rémi Garcia,
#         Boualem Lamraoui, Benoît Le Badezet, Benoit Loger
#-------------------------------------------------------------------------------

"""
    find_first_violation(solution::Solution, instance::Instance)

Return the index of the first car violating the paint_batch_limit constraint in the sequence,
return -1 if such a car does not exist
"""
function find_first_violation(solution::Solution, instance::Instance)
    first_violation = -1
    current_color = batch_color = instance.color_code[solution.sequence[1]]
    batch_size = 1
    for i in 2:instance.nb_cars
        current_color = instance.color_code[solution.sequence[i]]
        if current_color == batch_color
            batch_size += 1
        else
            batch_size = 1
            batch_color = current_color
        end
        if batch_size > instance.nb_paint_limitation && i > instance.nb_late_prec_day
            first_violation = i
            break
        end
    end
    return first_violation
end

"""
    repair!(solution::Solution, instance::Instance)

Apply 2 repair strategies on `solution`.
"""
function repair!(solution::Solution, instance::Instance)
    # First strategy
    RC_cars_groups = Dict{Int, Array{Int, 1}}()
    b0 = instance.nb_late_prec_day+1
    for car_pos in b0:instance.nb_cars
        car_RC_value = RC_value(solution.sequence[car_pos], instance)
        if !haskey(RC_cars_groups, car_RC_value)
            RC_cars_groups[car_RC_value] = [car_pos]
        else
            push!(RC_cars_groups[car_RC_value], car_pos)
        end
    end
    #filter!(x -> length(x.second) >= 2, RC_cars_groups)

    position = 1
    counter = 1
    current_color = instance.color_code[solution.sequence[position]]
    position += 1
    first_violation = 0
    while position <= instance.nb_cars
        if instance.color_code[solution.sequence[position]] == current_color
            counter += 1
        else
            counter = 1
            current_color = instance.color_code[solution.sequence[position]]
        end
        if counter > instance.nb_paint_limitation
            if position >= b0
                if first_violation == 0
                    first_violation = position
                end
                car_RC_value = RC_value(solution.sequence[position], instance)
                car_pos = 1
                len = length(RC_cars_groups[car_RC_value])
                while (car_pos <= len) && (instance.color_code[RC_cars_groups[car_RC_value][car_pos]] == current_color)
                    car_pos += 1
                end
                if car_pos <= len
                    move_exchange!(solution, position, car_pos, instance)
                    counter = first_violation - position
                    if first_violation >= position
                        position = first_violation - 1
                    else
                        position -= 1
                    end
                    first_violation = 0
                elseif first_violation >= position
                    position -= 2
                    if counter == 2*instance.nb_paint_limitation
                        # This strategy can't repair
                        position = first_violation
                    end
                end
            else
                if first_violation != 0
                    position = first_violation
                else
                    # pcc are not possible in nb_late_prec_day so we keep the counter
                end
            end
        end
        position += 1
    end

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
    #filter!(x -> length(x.second) >= 2, HPRC_cars_groups)

    position = 1
    counter = 1
    current_color = instance.color_code[solution.sequence[position]]
    position += 1
    first_violation = 0
    while position <= instance.nb_cars
        if instance.color_code[solution.sequence[position]] == current_color
            counter += 1
        else
            counter = 1
            current_color = instance.color_code[solution.sequence[position]]
        end
        if counter > instance.nb_paint_limitation
            if position >= b0
                if first_violation == 0
                    first_violation = position
                end
                car_HPRC_value = HPRC_value(solution.sequence[position], instance)
                car_pos = 1
                len = length(HPRC_cars_groups[car_HPRC_value])
                while (car_pos <= len) && (instance.color_code[HPRC_cars_groups[car_HPRC_value][car_pos]] == current_color)
                    car_pos += 1
                end
                if car_pos <= len
                    move_exchange!(solution, position, car_pos, instance)
                    counter = first_violation - position
                    if first_violation >= position
                        position = first_violation - 1
                    else
                        position -= 1
                    end
                    first_violation = 0
                elseif first_violation >= position
                    position -= 2
                    if counter == 2*instance.nb_paint_limitation
                        # This strategy can't repair
                        position = first_violation
                    end
                end
            else
                if first_violation != 0
                    position = first_violation
                else
                    # pcc are not possible in nb_late_prec_day so we keep the counter
                end
            end
        end
        position += 1
    end

    # Second strategy
    println()
    first_violation = find_first_violation(solution, instance)
    b0 = instance.nb_late_prec_day+1
    while first_violation != -1
        # Compute the best_insertion index
        solution_value = weighted_sum(solution, instance)
        cost_insertion = zeros(instance.nb_cars)
        for i in b0:instance.nb_cars
            if i <= instance.nb_late_prec_day || i == first_violation # avoiding insterting in sequence from the precedent day and at the same position
                cost_insertion[i] = Inf
            else
                #checking for validity of insertion :  if it does not add an other violation of Paint batch constraint
                batch_size = 1
                batch_color = instance.color_code[solution.sequence[first_violation]]
                if instance.color_code[solution.sequence[i]] == batch_color # if inserting create a batch of length greater than one
                    batch_size += 1
                    j = 1
                    same_batch_sup = true
                    same_batch_inf = true
                    while same_batch_inf || same_batch_sup
                        if i-j > 0 && instance.color_code[solution.sequence[i-j]] == batch_color && same_batch_inf
                            batch_size += 1
                        else
                            same_batch_inf = false
                        end

                        if i+j <= instance.nb_cars && instance.color_code[solution.sequence[i+j]] == batch_color && same_batch_sup
                            batch_size += 1
                        else
                            same_batch_sup = false
                        end
                        j += 1
                    end
                end
                if batch_size > instance.nb_paint_limitation
                    cost_insertion[i] = Inf
                else
                    solution_copy = deepcopy(solution)
                    move_insertion!(solution, first_violation, i, instance)
                    cost_insertion[i] = weighted_sum(solution_copy, instance) - solution_value
                end
            end
        end
        best_insertion = argmin(cost_insertion)[1]
        move_insertion!(solution, first_violation, best_insertion, instance)

        first_violation = find_first_violation(solution, instance)
    end

    return solution
end

"""
    perturbation_VNS_PCC_exchange(solution_init::Solution, k::Int, instance::Instance)

Returns a new solution obtain by `k` random exchanges between cars. Exchanged
cars must have the same HPRC constraints.
"""
function perturbation_VNS_PCC_exchange(solution_init::Solution, k::Int, instance::Instance)
    solution = deepcopy(solution_init)
    HPRC_cars_groups = Dict{Int, Array{Int, 1}}()
    b0 = instance.nb_late_prec_day+1
    for car_pos in b0:instance.nb_cars
        car_HPRC_value = HPRC_value(solution.sequence[car_pos])
        if !haskey(HPRC_cars_groups, car_HPRC_value)
            HPRC_cars_groups[car_HPRC_value] = [car_pos]
        else
            push!(HPRC_cars_groups[car_HPRC_value], car_pos)
        end
    end
    filter!(x -> length(x.second) >= 2, all_list_same_HPRC)

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
    perturbation_VNS_PCC_insertion(solution_init::Solution, k::Int, instance::Instance)

Delete k vehicles from the sequence and add them back in the sequence according
to a greedy criterion.
"""
function perturbation_VNS_PCC_insertion(solution_init::Solution, k::Int, instance::Instance)
    solution = deepcopy(solution_init)
    b0 = instance.nb_late_prec_day+1
    array_insertion = zeros(Int, k)

    for car_pos in 1:k
        array_insertion[car_pos] = rand(b0:instance.nb_cars)
        while array_insertion[car_pos] in array_insertion[1:(car_pos-1)]
            array_insertion[car_pos] = rand(b0:instance.nb_cars)
        end
    end

    # Put every index at the end
    sort!(array_insertion, rev=true) # sort is important to avoid to compute offset.
    for car_pos in array_insertion
        move_insertion!(solution, car_pos, instance.nb_cars, instance)
    end

    # Best insert
    counter = 1
    for car_pos in (instance.nb_cars-k+1):instance.nb_cars
        matrix_deltas = cost_move_insertion(solution, car_pos, instance, 3)
        best_insertion = array_insertion[counter]
        best_delta = sum([WEIGHTS_OBJECTIVE_FUNCTION[i] * matrix_deltas[array_insertion[counter], i] for i in 1:3])
        sequence = solution.sequence[1:(instance.nb_cars-k+counter)]
        sequence[instance.nb_cars-k+1] = solution.sequence[car_pos]
        for position in (instance.nb_cars-k+1):-1:1
            if matrix_deltas[position, 1] <= 0 && is_sequence_valid(sequence, instance.nb_cars-k+counter, instance)
                delta = sum([WEIGHTS_OBJECTIVE_FUNCTION[i] * matrix_deltas[position, i] for i in 1:3])
                if delta < best_delta
                    best_delta = delta
                    best_insertion = position
                end
            end
            if position > 1
                sequence[position], sequence[position-1] = sequence[position-1], sequence[position]
            end
        end
        move_insertion!(solution, car_pos, best_insertion, instance)
        counter += 1
    end

    return solution
end

"""

"""
function intensification_VNS_PCC!(solution::Solution, instance::Instance)

    return solution
end

"""

"""
function localsearch_VNS_PCC!(solution::Solution, instance::Instance)
    #TODO JFontaine needs to take a look
    b0 = instance.nb_late_prec_day+1
    improved = true
    sequence = copy(solution.sequence)
    while improved
        solution_cost = cost(solution, instance, 3)
        phi = WEIGHTS_OBJECTIVE_FUNCTION[2] * solution_cost[2] + WEIGHTS_OBJECTIVE_FUNCTION[3] * solution_cost[3]
        for i in b0:instance.nb_cars
            best_delta = 0
            list = Array{Int, 1}()
            for j in (i+1):instance.nb_cars # exchange (i, j) is the same as exchange (j, i)
                if same_HPRC(solution, i, j, instance)
                    delta = cost_move_exchange(solution, i, j, instance, 2)[2]
                    sequence[i], sequence[j] = sequence[j], sequence[i]
                    if delta < best_delta && is_sequence_valid(sequence, instance.nb_cars, instance)
                        list = [j]
                        best_delta = delta
                    elseif delta == best_delta
                        push!(list, j)
                    end
                    sequence[i], sequence[j] = sequence[j], sequence[i]
                end
            end
            if !isempty(list)
                k = rand(list)
                move_exchange!(solution, i, k, instance)
                sequence[i], sequence[k] = sequence[k], sequence[i]
            end
        end
        solution_cost = cost(solution, instance, 3)
        if phi == WEIGHTS_OBJECTIVE_FUNCTION[2] * solution_cost[2] + WEIGHTS_OBJECTIVE_FUNCTION[3] * solution_cost[3]
            improved = false
        end
    end
    return solution
end

"""

"""
function VNS_PCC(solution::Solution, instance::Instance, start_time::UInt)
    repair!(solution, instance)
    perturbations = Array{Function, 1}([perturbation_VNS_PCC_insertion, perturbation_VNS_PCC_exchange])
    p = 1
    k = VNS_PCC_MINMAX[p+1][1]
    cost_solution = weighted_sum(solution, instance)
    cost_HPRC_solution = cost(solution, instance, 1)[1]
    while TIME_LIMIT > (time_ns() - start_time) / 1.0e9
        while (k <= VNS_PCC_MINMAX[p+1][2]) && (TIME_LIMIT > (time_ns() - start_time) / 1.0e9)
            solution_perturbation = perturbations[p](solution, k, instance)
            if cost_HPRC_solution < cost(solution_perturbation, instance, 1)[1]
                solution_perturbation = deepcopy(solution)
            end
            localsearch_VNS_PCC!(solution_perturbation, instance)
            cost_solution_perturbation = weighted_sum(solution_perturbation, instance)
            if cost_solution_perturbation < cost_solution
                k = VNS_PCC_MINMAX[p+1][1]
            else
                k += 1
            end
            if cost_solution_perturbation <= cost_solution
                println("Best find!")
                solution = deepcopy(solution_perturbation)
                cost_HPRC_solution = cost(solution, instance, 1)[1]
                cost_solution = weighted_sum(solution, instance)
            end
        end
        intensification_VNS_PCC!(solution, instance)
        p = 1 - p
        VNS_PCC_MINMAX[p+1][1]
    end
    return solution
end
