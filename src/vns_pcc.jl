#-------------------------------------------------------------------------------
# File: vns_pcc.jl
# Description: This files contains all function that are used in VNS_PCC.
# Date: November 03, 2019
# Author: Jonathan Fontaine, Killian Fretaud, Rémi Garcia,
#         Boualem Lamraoui, Benoît Le Badezet, Benoit Loger
#-------------------------------------------------------------------------------

"""
    repair!(solution::Solution, instance::Instance)

Apply 2 repair strategies on `solution`.
"""
function repair!(solution::Solution, instance::Instance)
    #TODO
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
    for car_pos in (b0+1):solution.n
        car_HPRC_value = HPRC_value(solution.sequence[car_pos])
        if !haskey(HPRC_cars_groups, car_HPRC_value)
            HPRC_cars_groups[car_HPRC_value] = [car_pos]
        else
            push!(HPRC_cars_groups[car_HPRC_value], car_pos)
        end
    end
    filter!(x -> length(x.second) >= 2, all_list_same_HPRC)

    for _ in 1:k
        HPRC_group = rand(keys(HPRC_cars_groups))
        car_pos_a = rand(HPRC_cars_groups[HPRC_group])
        car_pos_b = rand(HPRC_cars_groups[HPRC_group])
        # Must have the same options
        while car_pos_a == car_pos_b
            car_pos_b = rand(HPRC_cars_groups[HPRC_group])
        end
        move_exchange!(solution, car_pos_a, car_pos_b, instance)
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
        array_insertion[car_pos] = rand(b0:solution.n)
        while array_insertion[car_pos] in array_insertion[1:(car_pos-1)]
            array_insertion[car_pos] = rand(b0:solution.n)
        end
    end

    # Put every index at the end
    sort!(array_insertion, rev=true) # sort is important to avoid to compute offset.
    for i in array_insertion
        move_insertion!(solution, i, solution.n, instance)
    end

    # Best insert
    for i in (solution.n-k):solution.n
        j_best = b0
        cost_best = weighted_sum_VNS_LPRC(cost_move_insertion(solution, i, j_best, instance, 2))
        for j in (b0+1):i
            cost = weighted_sum_VNS_LPRC(cost_move_insertion(solution, i, j, instance, 2))
            if cost < cost_best
                j_best = j
                cost_best = cost
            end
        end
        move_insertion!(solution, i, j_best, instance)
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
    while improved
        solution_cost = cost(solution, instance, 3)
        phi = WEIGHTS_OBJECTIVE_FUNCTION[2] * solution_cost[2] + WEIGHTS_OBJECTIVE_FUNCTION[3] * solution_cost[3]
        for i in b0:solution.n
            best_delta = 0
            list = Array{Int, 1}()
            for j in (i+1):solution.n # exchange (i, j) is the same as exchange (j, i)
                if same_HPRC(solution, i, j, instance)
                    delta = cost_move_exchange(solution, i, j, instance, 2)[2]
                    if delta < best_delta
                        list = [j]
                        best_delta = delta
                    elseif delta == best_delta
                        push!(list, j)
                    end
                end
            end
            if !isempty(list)
                k = rand(list)
                move_exchange!(solution, i, k, instance)
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
    cost_solution = sum_cost(solution, instance)
    cost_HPRC_solution = cost(solution, instance, 1)[1]
    while TIME_LIMIT > (time_ns() - start_time) / 1.0e9
        while k <= VNS_PCC_MINMAX[p+1][2]
            solution_perturbation = perturbations[p](solution, k, instance)
            if cost_HPRC_solution < cost(solution_perturbation, instance, 1)[1]
                solution_perturbation = deepcopy(solution)
            end
            localsearch_VNS_PCC!(solution_perturbation, instance)
            cost_solution_perturbation = sum_cost(solution_perturbation, instance)
            if cost_solution_perturbation < cost_solution
                k = VNS_PCC_MINMAX[p+1][1]
            else
                k += 1
            end
            if cost_solution_perturbation <= cost_solution
                solution = deepcopy(solution_perturbation)
                cost_HPRC_solution = cost(solution, instance, 1)[1]
                cost_solution = sum_cost(solution, instance)
            end
        end
        intensification_VNS_PCC!(solution, instance)
        p = 1 - p
        VNS_PCC_MINMAX[p+1][1]
    end

    return solution
end
