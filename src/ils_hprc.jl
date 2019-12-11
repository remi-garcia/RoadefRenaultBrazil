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
    perturbation_ils_hprc(solution::Solution, instance::Instance,
                          k::Int, critical_cars::Array{Int,1})

Removes `k` cars of `solution` and inserts them back in the sequence.
"""
function perturbation_ils_hprc(solution_init::Solution, instance::Instance,
                               k::Int, critical_cars::Array{Int,1})
    solution = deepcopy(solution_init)
    k = min(k, length(critical_cars))
    remove!(solution, instance, k, critical_cars)
    for i in 1:k
        greedy_add!(solution, instance, instance.nb_cars, 1)
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
    while TIME_PART_ILS * TIME_LIMIT_LEX > (time_ns() - start_time) / 1.0e9
        overall_delta = 0
        b0 = instance.nb_late_prec_day + 1      #First car of the current production day
        for i in b0:instance.nb_cars
            hprc_current_car = instance.HPRC_keys[solution.sequence[i]]
            best_delta = 0
            new_possible_positions = Array{Int, 1}()
            for j in b0:instance.nb_cars
                if hprc_current_car != instance.HPRC_keys[solution.sequence[j]]
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
    while TIME_PART_ILS * TIME_LIMIT_LEX > (time_ns() - start_time) / 1.0e9
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
                                         critical_cars::Array{Int, 1}, start_time::UInt)

Performs a local search on `solution` using only exchange moves with respect to `instance`
for well chosen cars tagged in `critical_cars`.
"""
function fast_local_search_exchange_ils_hprc!(solution::Solution, instance::Instance,
                                              critical_cars::Array{Int, 1}, start_time::UInt)
    while !isempty(critical_cars) && (TIME_PART_ILS * TIME_LIMIT_LEX > (time_ns() - start_time) / 1.0e9)
        b0 = instance.nb_late_prec_day + 1      #First car of the current production day
        position_car_a = rand(critical_cars)
        hprc_current_car = instance.HPRC_keys[solution.sequence[position_car_a]]
        best_delta = 0
        new_possible_positions = Array{Int, 1}()
        for position_car_b in b0:instance.nb_cars
            if hprc_current_car != instance.HPRC_keys[solution.sequence[position_car_b]]
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
            deleteat!(critical_cars, findfirst(isequal(position_car_a), critical_cars))
        else
            deleteat!(critical_cars, findfirst(isequal(position_car_a), critical_cars))
        end
    end

    return solution
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
    critical_cars = find_critical_cars(solution_init, instance, 1)
    solution = perturbation_ils_hprc(solution_init, instance, NBCAR_DIVERSIFICATION, critical_cars)
    return solution
end

"""
    ILS_HPRC(solution_init::Solution, instance::Instance, start_time::UInt)

Main function of the ILS metaheuristic. Improves the `solution_init` on its first objective
with respect to `instance`.
"""
function ILS_HPRC(solution_init::Solution, instance::Instance, start_time::UInt)
    i = 0                               # Number of iterations since the last improvement
    nb_strong_perturbation = 0                      # Number of restarts done for a solution
    solution = deepcopy(solution_init)
    solution_opt = deepcopy(solution_init)
    lastopt = deepcopy(solution_init)
    cond = 0 #TODO
    while cond < STOPPING_CRITERIA_ILS_HPRC && cost_HPRC(solution_opt, instance) != 0 && (TIME_PART_ILS * TIME_LIMIT_LEX > (time_ns() - start_time) / 1.0e9)
        critical_cars = find_critical_cars(solution, instance, 1)
        neighbor = perturbation_ils_hprc(solution, instance, NBCAR_PERTURBATION, critical_cars)
        critical_cars = find_critical_cars(neighbor, instance, 1)
        if length(critical_cars) > (instance.nb_cars * 0.6)
            neighbor = local_search_exchange_ils_hprc!(neighbor, instance, start_time)
        else
            neighbor = fast_local_search_exchange_ils_hprc!(neighbor, instance, critical_cars, start_time)
        end
        if cost_HPRC(solution, instance) <= cost_HPRC(neighbor, instance)
            solution = neighbor
        end
        if i == ALPHA_ILS
            solution = intensification_ils_hprc!(solution, instance, start_time)
        end
        if i == BETA_ILS
            cond = cond + 1
            if cost_HPRC(lastopt, instance) > cost_HPRC(solution_opt, instance)
                lastopt = solution_opt
                cond = 0
            end
            if cost_HPRC(solution, instance) > cost_HPRC(solution_opt, instance)
                solution = solution_opt                   # Restart from solution*
                i = 0
            else
                if nb_strong_perturbation < 3
                    solution = restart_ils_hprc(solution, instance)       # Restart from strong perturbation (50 cars)
                    nb_strong_perturbation = nb_strong_perturbation + 1
                    i = 0
                else
                    solution = greedy(instance)                    # Regenerate an initial solution and restart
                    nb_strong_perturbation = 0
                    i = 0
                end
            end
        end
        if cost_HPRC(solution, instance) < cost_HPRC(solution_opt, instance)            # There is an improvement
            solution_opt = solution
            i = 0                   # So the number of iterations since the last improvement shall return to 0
        else
            i = i + 1
        end
    end
    return solution_opt
end
