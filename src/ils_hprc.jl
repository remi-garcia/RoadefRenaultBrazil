#-------------------------------------------------------------------------------
# File: ils_hprc.jl
# Description: ILS for the RENAULT Roadef 2005 challenge
#   inspired by work of
#   Celso C. Ribeiro, Daniel Aloise, Thiago F. Noronha,
#   Caroline Rocha, Sebastián Urrutia
#
# Date: November 25, 2019
# Author: Jonathan Fontaine, Killian Fretaud, Rémi Garcia,
#         Boualem Lamraoui, Benoît Le Badezet, Benoit Loger
#-------------------------------------------------------------------------------

"""
    remove!(solution_init::Solution, instance::Instance,
            k::Int, crit::Array{Int, 1})

Removes `k` critical cars of the sequence of `solution_init`.
"""
function remove!(solution_init::Solution, instance::Instance,
                 k::Int, crit::Array{Int, 1})
    solution = deepcopy(solution_init)
    indices = sort(randperm(length(crit))[1:k])
    crit_sort = sort(crit, rev = true)
    for i in 1:k
        position = crit_sort[indices[i]]
        move_insertion!(solution, position, instance.nb_cars, instance)
    end

    return solution
end

"""
    greedy_add!(solution::Solution, instance::Instance, k::Int)

Reinserts last car in the sequence of `solution`.
"""
function greedy_add!(solution::Solution, instance::Instance, k::Int)
    b0 = instance.nb_late_prec_day + 1
    costs = cost_move_insertion(solution, instance.nb_cars, instance, 1)
    delta = costs[b0]
    posdelta = b0
    for pos in b0+1:instance.nb_cars-k
        if costs[pos] < delta
            delta = costs[pos]
            posdelta = pos
        end
    end
    move_insertion!(solution, instance.nb_cars, posdelta, instance)

    return solution
end

"""
    perturbation_ils_hprc(solution::Solution, instance::Instance,
                          k::Int, crit::Array{Int,1})

Removes `k` cars of `solution` and inserts them back in the sequence.
"""
function perturbation_ils_hprc(solution_init::Solution, instance::Instance,
                               k::Int, crit::Array{Int,1})
    solution = deepcopy(solution_init)
    k = minimum([k, length(crit)])
    remove!(solution, instance, k, crit)
    for i in 1:k
        greedy_add!(solution, instance, k)
    end

    return solution
end

cost_HPRC(solution::Solution, instance::Instance) = cost(solution, instance, 1)[1]

"""
    local_search_exchange_ils_hprc!(solution::Solution, instance::Instance,
                                    start_time::UInt)

Performs a local search on `solution` using only exchange moves with respect to
`instance`.
"""
function local_search_exchange_ils_hprc!(solution::Solution, instance::Instance,
                                         start_time::UInt)
    while 0.9 * TIME_LIMIT > (time_ns() - start_time) / 1.0e9
        overall_delta = 0
        b0 = instance.nb_late_prec_day + 1      #First car of the current production day
        for i in b0:instance.nb_cars
            hprc_current_car = HPRC_value(solution.sequence[i], instance)
            best_delta = 0
            new_possible_positions = Array{Int, 1}()
            for j in b0:instance.nb_cars
                if hprc_current_car != HPRC_value(solution.sequence[j], instance)
                    delta = cost_move_exchange(solution, i, j, instance,1)[1]
                    if delta < best_delta
                        empty!(new_possible_positions)
                        push!(new_possible_positions, j)
                        best_delta = delta
                    elseif delta == best_delta
                        push!(new_possible_positions, j)
                    end
                end
            end
            if !isempty(new_possible_positions)
                k = rand(new_possible_positions)
                move_exchange!(solution, i, k, instance)
            end
            overall_delta += best_delta
        end
        if overall_delta == 0
            break
        end
    end

    return solution
end

"""
    local_search_insertion_ils_hprc!(solution::Solution, instance::Instance,
                                     start_time::UInt)

Performs a local search on `solution` using only insertion moves with respect to
`instance`.
"""
function local_search_insertion_ils_hprc!(solution::Solution, instance::Instance,
                                          start_time::UInt)
    while 0.9 * TIME_LIMIT > (time_ns() - start_time) / 1.0e9
        overall_delta = 0
        b0 = instance.nb_late_prec_day + 1      #First car of the current production day
        for i in b0:instance.nb_cars
            best_delta = 0
            new_possible_positions = Array{Int, 1}()
            costs = cost_move_insertion(solution,i,instance,1)
            for j in b0:instance.nb_cars
                delta = costs[j, 1]
                if delta < best_delta
                    empty!(new_possible_positions)
                    push!(new_possible_positions, j)
                    best_delta = delta
                elseif delta == best_delta
                    push!(new_possible_positions, j)
                end
            end
            if !isempty(new_possible_positions)
                k = rand(new_possible_positions)
                move_insertion!(solution, i, k, instance)
            end
            overall_delta += best_delta
        end
        if overall_delta == 0
            break
        end
    end

    return solution
end

"""
    fast_local_search_exchange_ils_hprc!(solution::Solution, instance::Instance,
                                         crit::Array{Int, 1}, start_time::UInt)

Performs a local search on `solution` using only exchange moves with respect to `instance`
for well chosen cars tagged in `crit`.
"""
function fast_local_search_exchange_ils_hprc!(solution::Solution, instance::Instance,
                                              crit::Array{Int, 1}, start_time::UInt)
    while !isempty(crit) && (0.9 * TIME_LIMIT > (time_ns() - start_time) / 1.0e9)
        b0 = instance.nb_late_prec_day + 1      #First car of the current production day
        position_car_a = rand(crit)
        hprc_current_car = HPRC_value(solution.sequence[position_car_a], instance)
        best_delta = 0
        new_possible_positions = Array{Int, 1}()
        for position_car_b in b0:instance.nb_cars
            if hprc_current_car != HPRC_value(solution.sequence[position_car_b], instance)
                delta = cost_move_exchange(solution, position_car_a, position_car_b, instance, 1)[1]
                if delta < best_delta
                    empty!(new_possible_positions)
                    push!(new_possible_positions, position_car_b)
                    best_delta = delta
                elseif delta == best_delta
                    push!(new_possible_positions, position_car_b)
                end
            end
        end
        if !isempty(new_possible_positions)
            k = rand(new_possible_positions)
            move_exchange!(solution, position_car_a, k, instance)
            # Update critical cars:
            #TODO
            deleteat!(crit, findfirst(isequal(position_car_a), crit))
        else
            deleteat!(crit, findfirst(isequal(position_car_a), crit))
        end
    end

    return solution
end

"""
    critical_cars_VNS_LPRC(solution::Solution, instance::Instance)

Returns the set cars involved in at least one HPRC violation.
"""
function critical_cars_ILS_HPRC(solution::Solution, instance::Instance)
    critical_car = Set{Int}()
    b0 = instance.nb_late_prec_day+1
    for index_car in b0:instance.nb_cars
        for option in 1:instance.nb_HPRC
            if solution.M1[option, index_car] > instance.RC_p[option]
                index_car_lim = index_car + min(instance.RC_p[option], instance.nb_cars-index_car)
                for index_car_add in index_car:index_car_lim
                    if instance.RC_flag[solution.sequence[index_car_add], option]
                        push!(critical_car, index_car_add)
                    end
                end
            end
        end
    end
    return collect(critical_car)
end

"""
    intensification_ils_hprc!(solution::Solution, instance::Instance,
                              start_time::UInt)

Performs a local search on `solution` using insertion moves first then exchange moves with
respect to `instance`.
"""
function intensification_ils_hprc!(solution::Solution, instance::Instance,
                                   start_time::UInt)
    local_search_insertion_ils_hprc!(solution, instance, start_time)
    local_search_exchange_ils_hprc!(solution, instance, start_time)
    return solution
end

"""
    restart_ils_hprc(solution::Solution, instance::Instance)


"""
function restart_ils_hprc(solution_init::Solution, instance::Instance)
    crit = critical_cars_ILS_HPRC(solution_init, instance)
    solution = perturbation_ils_hprc(solution_init, instance, NBCAR_DIVERSIFICATION, crit)
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
        crit = critical_cars_ILS_HPRC(s, instance)
        neighbor = perturbation_ils_hprc(s, instance, NBCAR_PERTURBATION, crit)
        crit = critical_cars_ILS_HPRC(neighbor, instance)
        if length(crit) > (instance.nb_cars * 0.6)
            neighbor = local_search_exchange_ils_hprc!(neighbor, instance, start_time)
        else
            neighbor = fast_local_search_exchange_ils_hprc!(neighbor, instance, crit, start_time)
        end
        if cost_HPRC(s, instance) <= cost_HPRC(neighbor, instance)
            s = neighbor
        end
        if i == ALPHA_ILS
            s = intensification_ils_hprc!(s, instance, start_time)
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
