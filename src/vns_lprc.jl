#-------------------------------------------------------------------------------
# File: vns_lprc.jl
# Description: This files contains all function that are used in VNS_LPRC.
# Date: October 31, 2019
# Author: Jonathan Fontaine, Killian Fretaud, Rémi Garcia,
#         Boualem Lamraoui, Benoît Le Badezet, Benoit Loger
#-------------------------------------------------------------------------------

# Make k randomly exchange, each exchange occurs in the same HPRC level, to avoid increase it.
function perturbation_VNS_LPRC_exchange(solution::Solution, k::Int, instance::Instance)
    # Dict that contain for each HRPC level an array of all index that have this HPRC level.
    all_list_same_HPRC = Dict{Int, Array{Int, 1}}()
    current_HPRC = -1
    for i in 1:solution.n
        temp_HPRC = HPRC_level(solution, i, instance)
        if temp_HPRC != current_HPRC
            current_HPRC = temp_HPRC
            all_list_same_HPRC[current_HPRC] = Array{Int, 1}()
        end
        push!(all_list_same_HPRC[current_HPRC], i)
    end
    # Delete all HPRC with length less than 2 (Can't exchange 2 vehicles if there is less than 2)
    filter!(x -> length(x.second) >= 2, all_list_same_HPRC)

    sol = deepcopy(solution)

    for iterator in 1:k
        same_HPRC_array = rand(all_list_same_HPRC).second
        i = rand(same_HPRC_array)
        j = rand(same_HPRC_array)
        # Cannot be the same
        while i == j
            j = rand(same_HPRC_array)
        end
        move_exchange!(sol, i, j, instance)
    end

    return sol
end

# Delete k vehicles from the sequence and add them in the sequence according a greedy criterion.
function perturbation_VNS_LPRC_insertion(solution::Solution, k::Int, instance::Instance)
    sol = deepcopy(solution)

    array_insertion = Array{Int, 1}()

    push!(array_insertion, rand(1:sol.n))

    for iterator in 2:k
        r = rand(1:sol.n)
        while r in array_insertion
            r = rand(1:sol.n)
        end
        push!(array_insertion, r)
    end

    # Put every index at the end
    sort!(array_insertion, rev=true) # sort is important to avoid to compute offset.
    for i in array_insertion
        move_insertion!(sol, i, sol.n, instance)
    end

    # Best insert
    for i in (sol.n-k):sol.n
        j_best = 1
        cost_best = cost_move_insertion(sol, i, j_best, instance, 2)
        for j in 2:(sol.n-k+i-1)
            cost = cost_move_insertion(sol, i, j, instance, 2)
            if cost < cost_best
                j_best = j
                cost_best = cost
            end
        end
        move_insertion!(sol, i, j_best, instance)
    end

    return sol
end

# Perturbation of VNS_LPRC
function perturbation_VNS_LPRC(solution::Solution, p::Int, k::Int, instance::Instance)
    if p == 1
        return perturbation_VNS_LPRC_exchange(solution, k, instance)
    else
        return perturbation_VNS_LPRC_insertion(solution, k, instance)
    end
end

# The Local Search is based on a car exchange move.
function localSearch_VNS_LPRC!(solution::Solution, perturbation_exchange::Bool, instance::Instance)

    # useful variables
    nb_vehicles = length(solution.sequence)
    b0 = instance.nb_late_prec_day+1

    improved = true
    while improved
        phi = cost_VNS_LPRC(solution, instance)
        for i in b0:nb_vehicles
            best_delta = 0
            list = Array{Int, 1}()
            for j in (i+1):nb_vehicles # exchange (i, j) is the same as exchange (j, i)
                if !perturbation_exchange || same_HPRC(solution, i, j, instance)
                    delta = cost_move_exchange(solution, i, j, instance, 2)
                    if delta < best_delta
                        list = [j]
                        best_delta = delta
                    elseif delta == best_delta
                        push!(list, j)
                    end
                end
            end
            if list != []
                k = rand(list)
                move_exchange!(solution, i, k, instance)
            end
        end
        if phi == cost_VNS_LPRC(solution, instance)
            improved = false
        end
    end
end


function localSearch_intensification_VNS_LPRC!(solution::Solution, alpha::Int, cost_move::Function, move!::Function, instance::Instance)
    # useful variables
    nb_vehicles = length(solution.sequence)
    b0 = instance.nb_late_prec_day+1

    nb_non_improved = 0
    while nb_non_improved < alpha
        phi = cost_VNS_LPRC(solution, instance)
        for i in b0:nb_vehicles
            best_delta = 0
            list = Array{Int, 1}()
            for j in b0:nb_vehicles
                delta = cost_move(solution, i, j, instance, 2)
                if delta < best_delta
                    list = [j]
                    best_delta = delta
                elseif delta == best_delta
                    push!(list, j)
                end
            end
            if list != []
                k = rand(list)
                move!(solution, i, k, instance)
            end
        end
        nb_non_improved += 1
        if phi < cost_VNS_LPRC(solution, instance)
            nb_non_improved = 0
        end
    end
end

# Apply two local search, first one with insertion move, and the second one with exchange move.
function intensification_VNS_LPRC!(solution::Solution, instance::Instance)
    localSearch_intensification_VNS_LPRC!(solution, VNS_LPRC_ALPHA_PERTURBATION, cost_move_insertion, move_insertion!, instance)
    localSearch_intensification_VNS_LPRC!(solution, VNS_LPRC_ALPHA_PERTURBATION, cost_move_exchange, move_exchange!, instance)
end

# Return a tuple of solution, first element is the cost,and the second one is the number of HRPC violated.
function cost_VNS_LPRC(solution::Solution, instance::Instance)
    nb_HPRC_violated = sum(solution.M2[i, end] for i in 1:instance.nb_HPRC)
    nb_LPRC_violated = sum(solution.M2[instance.nb_HPRC + i, end] for i in 1:instance.nb_LPRC)
    cost = WEIGHTS_OBJECTIVE_FUNCTION[1] * nb_HPRC_violated + WEIGHTS_OBJECTIVE_FUNCTION[2] * nb_LPRC_violated
    return cost
end

# function that determine if left is better than right.
function is_better_VNS_LPRC(left::Solution, right::Solution, instance::Instance)
    left_cost = cost_VNS_LPRC(left, instance)
    right_cost = cost_VNS_LPRC(right, instance)

    nb_HPRC_violated_left = HPRC_level(left, left.n, instance)
    nb_HPRC_violated_right = HPRC_level(right, left.n, instance)

    cost_better = left_cost < right_cost
    HPRC_not_worse = nb_HPRC_violated_left <= nb_HPRC_violated_right

    return  cost_better && HPRC_not_worse
end

# VNS-LPRC algorithm describe in section 6.
function VNS_LPRC(solution::Solution, instance::Instance)

    # We note that p = 0 is for insertion move and p = 1 is for exchange move
    # because section 6.1 and 6.5 contradict themselves

    # solutions
    s = deepcopy(solution)
    s_opt = s
    # variable of the algorithm
    k_min = [VNS_LPRC_MIN_INSERT, VNS_LPRC_MIN_EXCHANGE]
    k_max = [VNS_LPRC_MAX_INSERT, VNS_LPRC_MAX_EXCHANGE]
    p = 1
    k = k_min[p+1]
    nb_intens_not_better = 0
    while nb_intens_not_better < VNS_LPRC_MAX_NON_IMPROVEMENT
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
