#-------------------------------------------------------------------------------
# File: ils_hprc.jl
# Description: ILS for the RENAULT Roadef 2005 challenge
#   inspired by work of
#   Celso C. Ribeiro, Daniel Aloise, Thiago F. Noronha,
#   Caroline Rocha, Sebastián Urrutia
#
# Date: November 03, 2019
# Author: Jonathan Fontaine, Killian Fretaud, Rémi Garcia,
#         Boualem Lamraoui, Benoît Le Badezet, Benoit Loger
#-------------------------------------------------------------------------------

"""
    remove(solution_init::Solution, instance::Instance, nbcar::Int, crit::Array{Int,1})

Removes `nbcar` cars of the sequence of `solution_init`. Cars must be tagged in `crit`.
"""
function remove(solution_init::Solution, instance::Instance, nbcar::Int, crit::Array{Int,1})
    solution = deepcopy(solution_init)
    i = instance.nb_late_prec_day+1
    nb_removed = 0
    while i <= length(crit) && nb_removed <= nbcar
        #TODO Don't take the first nbcar cars but randomly pick nbcar cars
        if crit[i] == 1
            nb_removed = nb_removed + 1
            move_insertion!(solution, i, instance.nb_cars, instance)
            deleteat!(crit, i)
        else
            i = i + 1
        end
    end
    #update_matrices!(solution, length(crit), instance)
    return solution, nb_removed
end

"""
    greedy_add(solution::Solution, instance::Instance, nb_removed::Int)

Inserts `car` in the sequence of `solution`.
"""
#TODO Need rework
function greedy_add(solution_init::Solution, instance::Instance, nb_removed::Int)
    b0 = instance.nb_late_prec_day + 1
    solution = deepcopy(solution_init)
    costs = cost_move_insertion(solution, instance.nb_cars, instance, 1)
    delta = costs[b0]
    posdelta = b0
    for pos in b0+1:instance.nb_cars-nb_removed
        if costs[pos] < delta
            delta = costs[pos]
            posdelta = pos
        end
    end
    move_insertion!(solution, instance.nb_cars, posdelta, instance)
    return solution
end

"""
    perturbation_ils_hprc(solution::Solution, instance::Instance, nbcar::Int, crit::Array{Int,1})

Removes `nbcars` of `solution` and inserts them elsewhere in the sequence.
"""
function perturbation_ils_hprc(solution::Solution, instance::Instance, nbcar::Int, crit::Array{Int,1})
    sol, nb_removed = remove(solution, instance, nbcar, crit)
    for i in 1:nb_removed
        sol = greedy_add(sol, instance, nb_removed)
    end
    return sol
end

cost_HPRC(solution::Solution, instance::Instance) = cost(solution, instance, 1)[1]

"""
    local_search_exchange_ils_hprc(solution::Solution, instance::Instance)

Performs a local search on `solution` using only exchange moves with respect to `instance`.
"""
#TODO Need rework
function local_search_exchange_ils_hprc(solution::Solution, instance::Instance)
    while true
        phi = cost_HPRC(solution, instance)
        b0 = instance.nb_late_prec_day + 1      #First car of the current production day
        for i in b0:instance.nb_cars
            hprc_current_car = HPRC_value(i, instance)
            best_delta = 0
            L = Array{Int,1}(undef,0)
            for j in b0:instance.nb_cars
                if hprc_current_car != HPRC_value(j, instance)
                    delta = cost_move_exchange(solution, i, j, instance,1)[1]
                    if delta < best_delta
                        empty!(L)
                        push!(L, j)
                        best_delta = delta
                    elseif delta == best_delta
                        push!(L, j)
                    end
                end
            end
            if !isempty(L)
                k = rand(L)
                move_exchange!(solution, i, k, instance)
            end
        end
        if phi == cost_HPRC(solution, instance)
            break
        end
    end

    return solution
end

"""
    local_search_insertion_ils_hprc(solution::Solution, instance::Instance)

Performs a local search on `solution` using only insertion moves with respect to `instance`.
"""
function local_search_insertion_ils_hprc(solution::Solution, instance::Instance)
    while true
        phi = cost_HPRC(solution, instance)
        b0 = instance.nb_late_prec_day + 1      #First car of the current production day
        for i in b0:instance.nb_cars
            best_delta = 0
            L = Array{Int,1}(undef,0)
            costs = cost_move_insertion(solution,i,instance,1)
            for j in b0:instance.nb_cars
                delta = costs[j, 1]
                if delta < best_delta
                    empty!(L)
                    push!(L, j)
                    best_delta = delta
                elseif delta == best_delta
                    push!(L, j)
                end
            end
            if !isempty(L)
                k = rand(L)
                move_insertion!(solution, i, k, instance)
            end
        end
        if phi == cost_HPRC(solution, instance)
            break
        end
    end

    return solution
end

"""
    fast_local_search_exchange_ils_hprc(solution::Solution, instance::Instance, crit::Array{Int, 1})

Performs a local search on `solution` using only exchange moves with respect to `instance`
for well chosen cars tagged in `crit`.
"""
function fast_local_search_exchange_ils_hprc(solution::Solution, instance::Instance, crit::Array{Int, 1})
    while true
        phi = cost_HPRC(solution, instance)
        b0 = instance.nb_late_prec_day + 1      #First car of the current production day
        for i in b0:instance.nb_cars
            if crit[i] == 1
                hprc_current_car = HPRC_value(i, instance)
                best_delta = 0
                L = Array{Int,1}(undef,0)
                for j in b0:instance.nb_cars
                    if hprc_current_car != HPRC_value(j, instance)
                        delta = cost_move_exchange(solution, i, j, instance, 1)[1]
                        if delta < best_delta
                            empty!(L)
                            push!(L, j)
                            best_delta = delta
                        elseif delta == best_delta
                            push!(L, j)
                        end
                    end
                end
                if !isempty(L)
                    k = rand(L)
                    move_exchange!(solution, i, k, instance)
                end
            end
        end
        if phi == cost_HPRC(solution, instance)
            break
        end
    end

    return solution
end

"""
    criticalCars(solution::Solution, instance::Instance)

Indiquates which cars are involved in violation of HPRC and their number
"""
function criticalCars(solution::Solution, instance::Instance)
    criticars = zeros(Int, instance.nb_cars)             # criticars[i] = 1 if car i violate HPRC otherwhise criticars[i] = 0
    nb_crit = 0                             # Number of cars involved in HPRC violation.
    j = 1
    for opt in 1:instance.nb_HPRC
        car = 1
        while car <= instance.nb_cars
            if solution.M2[opt,car] > instance.RC_p[opt]
                cursor = 0
                while cursor < instance.RC_p[opt] && (car+cursor) <= instance.nb_cars
                    if instance.RC_flag[car+cursor, opt] == true && criticars[car + cursor] == 0
                        criticars[car + cursor] = 1
                        nb_crit = nb_crit + 1
                    end
                    cursor = cursor + 1
                end
            end
            car = car + 1
        end
    end

    return criticars, nb_crit
end

"""
    intensification_ils_hprc(solution::Solution, instance::Instance)

Performs a local search on `solution` using insertion moves first then exchange moves with
respect to `instance`.
"""
function intensification_ils_hprc(solution::Solution, instance::Instance)
    solution = local_search_insertion_ils_hprc(solution, instance)
    solution = local_search_exchange_ils_hprc(solution, instance)
    return solution
end

#TODO: signature
"""
    restart_ils_hprc(solution::Solution, instance::Instance)

"""
function restart_ils_hprc(solution::Solution, instance::Instance)
    crit = criticalCars(solution, instance)[1]
    solution = perturbation_ils_hprc(solution, instance, NBCAR_DIVERSIFICATION, crit)
    return solution
end

"""
    ILS_HPRC(solution::Solution, instance::Instance, start_time::UInt)

Main function of the ILS metaheuristic. Improves the `solution` on its first objective
with respect to `instance`.
"""
function ILS_HPRC(solution::Solution, instance::Instance, start_time::UInt)
    i = 0                               # Number of iterations since the last improvement
    nb_strong_perturbation = 0                      # Number of restarts done for a solution
    s = deepcopy(solution)
    s_opt = deepcopy(solution)
    lastopt = deepcopy(solution)
    cond = 0 #TODO
    while cond < STOPPING_CRITERIA_ILS_HPRC && cost_HPRC(s_opt, instance) != 0 && (0.9 * TIME_LIMIT > (time_ns() - start_time) / 1.0e9)
        println(i)
        crit = criticalCars(s, instance)
        neighbor = perturbation_ils_hprc(s, instance, NBCAR_PERTURBATION, crit[1])
        crit = criticalCars(neighbor, instance)
        if crit[2] > (instance.nb_cars * 0.6)
            @time neighbor = local_search_exchange_ils_hprc(neighbor, instance)
        else
            @time neighbor = fast_local_search_exchange_ils_hprc(neighbor, instance, crit[1])
        end
        if cost_HPRC(s, instance) <= cost_HPRC(neighbor, instance)
            s = neighbor
        end
        if i == ALPHA_ILS
            s = intensification_ils_hprc(s, instance)
        end
        if i == BETA_ILS
            cond = cond + 1
            if cost_HPRC(lastopt, instance) > cost_HPRC(s_opt, instance)
                lastopt = s_opt
                cond = 0
            end
            if cost_HPRC(s, instance) > cost_HPRC(s_opt, instance)
                s = s_opt                   # Restart from s*
                i = 0
            else
                if nb_strong_perturbation < 3
                    s = restart_ils_hprc(s, instance)       # Restart from strong perturbation (50 cars)
                    nb_strong_perturbation = nb_strong_perturbation + 1
                    i = 0
                else
                    s = greedy(instance)                    # Regenerate an initial solution and restart
                    nb_strong_perturbation = 0
                    i = 0
                end
            end
        end
        if cost_HPRC(s, instance) < cost_HPRC(s_opt, instance)            # There is an improvement
            s_opt = s
            i = 0                   # So the number of iterations since the last improvement shall return to 0
        else
            i = i + 1
        end
    end
    return s_opt
end
