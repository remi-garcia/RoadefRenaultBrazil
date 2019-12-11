#-------------------------------------------------------------------------------
# File: greedy.jl
# Description: This file contains all function used to construct
#         a first valid solution.
# Date: October 31, 2019
# Author: Jonathan Fontaine, Killian Fretaud, Rémi Garcia,
#         Boualem Lamraoui, Benoît Le Badezet, Benoit Loger
#-------------------------------------------------------------------------------

"""
    filter_on_max_criterion(candidates::Array{Int,1},
                            criterion::Union{Array{Int,1},Array{Float64,1}})

Takes a set of candidates and removes all elements with bad criterion.
"""
function filter_on_max_criterion(candidates::Array{Int,1},
                                 criterion::Union{Array{Int,1},Array{Float64,1}})
    tmp_candidates = [candidates[1]]
    max_criterion = criterion[1]
    for i in 2:length(criterion)
        # next candidate...
        if criterion[i] > max_criterion # ...is better (keep only him)
            tmp_candidates = [candidates[i]]
            max_criterion = criterion[i]
        elseif criterion[i] == max_criterion # ...is even (keep him too)
            push!(tmp_candidates, candidates[i])
        end # ...is worse (throw it away)
    end
    return tmp_candidates
end

"""
    filter_on_min_criterion(candidates::Array{Int,1},
                            criterion::Array{Int,1})

Takes a set of candidates and removes all elements with bad criterion.
"""
function filter_on_min_criterion(candidates::Array{Int,1},
                                 criterion::Array{Int,1})
    tmp_candidates = [candidates[1]]
    min_criterion = criterion[1]
    for i in 2:length(criterion)
        # next candidate...
        if criterion[i] < min_criterion # ...is better (keep only him)
            tmp_candidates = [candidates[i]]
            min_criterion = criterion[i]
        elseif criterion[i] == min_criterion # ...is even (keep him too)
            push!(tmp_candidates, candidates[i])
        end # ...is worse (throw it away)
    end
    return tmp_candidates
end

"""
    greedy(instance::Instances)

Takes an `Instance` and return a valid `Solution`.
"""
function greedy(instance::Instance)
    # The constructive greedy heuristic starts with a partial sequence formed
    # by the remaining cars from the previous day. We compute an empty sequence
    # with some cars already scheduled
    solution = init_solution(instance)
    # We have V the set of cars to be scheduled
    len = (instance.nb_cars) - (instance.nb_late_prec_day)
    V = collect((instance.nb_late_prec_day+1):(instance.nb_cars))

    # Compute for each option the number of cars who need it in V
    # TODO : Could be done in the parser and stocked in the instance
    rv = sum(instance.RC_flag,dims=1)

    # For the nb_late_prec_day first cars, update M1, M2, M3
    update_matrices!(solution, instance)

    # Initialization for first tie-break criterion
    # Compute for each option the number of cars who need it in Pi
    rpi = zeros(Int,instance.nb_HPRC)
    for i in 1:instance.nb_late_prec_day
        for j in 1:instance.nb_HPRC
            if instance.RC_flag[i,j]
                rpi[j] = rpi[j]+1
            end
        end
    end

    # The greedy criterion consists in choosing, at each iteration, the car
    # that induces the smallest number of new violations when inserted at
    # the end of the current partial sequence.
    for position in (instance.nb_late_prec_day+1):(instance.nb_cars)
        # Compute the number of violations caused by each car
        nb_new_violation = zeros(Int, len)
        for c in 1:len
            for j in 1:instance.nb_HPRC
                if instance.RC_flag[V[c], j]
                    last_ended_sequence = (position - instance.RC_q[j])
                    if last_ended_sequence > 0
                        nb_new_violation[c] += solution.M3[j, position-1] - solution.M3[j, last_ended_sequence]
                    else
                        nb_new_violation[c] += solution.M3[j, position-1]
                    end
                end
            end
        end

        # Compute the set of indices causing minimal-violation
        candidates = filter_on_min_criterion(V, nb_new_violation)

        # Two candidates or more - First tie break
        # If the average number of cars demanding a given option in the
        # partial sequence π is lower than that in the whole set V of vehicles,
        # then these cars should be encouraged to enter in the sequence.
        if length(candidates) > 1
            # Compute the tie break criterion for each candidates
            tie_break = zeros(Int, length(candidates))
            for i in 1:length(candidates)
                for j in 1:instance.nb_HPRC
                    cond1 = !instance.RC_flag[candidates[i],j]
                    cond2 = (rv[j]-rpi[j])/len > (rpi[j])/solution.length
                    tie_break[i] += Int(xor( cond1 , cond2 ))
                end
            end

            # Compute the new candidate list
            candidates = filter_on_max_criterion(candidates, tie_break)
        end

        # Two candidates or more - Second tie break
        # Cars that require options with higher utilization rates should enter.
        if length(candidates) > 1
            # Compute the utilization rate of each options
            utilization_rate = Array{Float64,1}(UndefInitializer(),instance.nb_HPRC)
            for j in 1:instance.nb_HPRC
                utilization_rate[j] = ( (rv[j] - rpi[j])/len ) / ( instance.RC_p[j] / instance.RC_q[j] )
            end
            tie_break = zeros(length(candidates))
            for i in 1:length(candidates)
                for j in 1:instance.nb_HPRC
                    tie_break[i] += instance.RC_flag[candidates[i],j] * utilization_rate[j]
                end
            end

            # Compute the new candidate list
            candidates = filter_on_max_criterion(candidates, tie_break)
        end

        # Two candidates or more - LPRC criterion
        # Choose the car that induces the smallest number of new violations of LPRC
        # when inserted at the end of the current partial sequence.
        if length(candidates) > 1
            # Compute the number of violations caused by each car
            nb_new_violation = zeros(Int, length(candidates))
            for ind in 1:length(candidates)
                c = candidates[ind]
                for j in (instance.nb_HPRC+1):(instance.nb_HPRC+instance.nb_LPRC)
                    if instance.RC_flag[c, j]
                        last_ended_sequence = (position - instance.RC_q[j])
                        if last_ended_sequence > 0
                            nb_new_violation[ind] += solution.M3[j, position-1] - solution.M3[j, last_ended_sequence]
                        else
                            nb_new_violation[ind] += solution.M3[j, position-1]
                        end
                    end
                end
            end
            candidates = filter_on_min_criterion(candidates, nb_new_violation)
        end

        c = rand(candidates)     # We have a valid candidate
        solution.sequence[position] = c
        solution.length += 1
        len = len - 1
        filter!(x->x≠c, V)    # The car is not in the list anymore

        # The utilization rates components are dynamically updated.
        # Update rpi with the options of c
        for j in 1:instance.nb_HPRC
            rpi[j] += Int(instance.RC_flag[c,j])
        end

        # Update M1, M2 and M3
        update_matrices_new_car!(solution, position, instance)
    end

    return solution
end

"""
    greedy_pcc(instance::Instances)

Takes an `Instance` and return a valid `Solution`.
"""
function greedy_pcc(instance::Instance)
    # The constructive greedy heuristic starts with a partial sequence formed
    # by the remaining cars from the previous day. We compute an empty sequence
    # with some cars already scheduled
    solution = init_solution(instance)
    # We have V the set of cars to be scheduled
    len = (instance.nb_cars) - (instance.nb_late_prec_day)
    V = collect((instance.nb_late_prec_day+1):(instance.nb_cars))

    repair_needed = false

    # Compute for each option the number of cars who need it in V
    # TODO : Could be done in the parser and stocked in the instance
    rv = sum(instance.RC_flag,dims=1)

    # For the nb_late_prec_day first cars, update M1, M2, M3
    update_matrices!(solution, instance)

    # Initialization for first tie-break criterion
    # Compute for each option the number of cars who need it in Pi
    rpi = zeros(Int,instance.nb_HPRC)
    for i in 1:instance.nb_late_prec_day
        for j in 1:instance.nb_HPRC
            if instance.RC_flag[i,j]
                rpi[j] = rpi[j]+1
            end
        end
    end

    # Get colors
    same_colors = Array{Array{Int, 1}, 1}()
    for color_groups in instance.same_color
        push!(same_colors, copy(color_groups.second))
    end
    sort!(same_colors, by = x -> length(x), rev = true)
    batch_size = 0

    # The greedy criterion consists in choosing, at each iteration, the car
    # that induces the smallest number of new violations when inserted at
    # the end of the current partial sequence.
    for position in (instance.nb_late_prec_day+1):(instance.nb_cars)
        # Compute the number of violations caused by each car
        nb_new_violation = zeros(Int, len) .+ typemax(Int)
        for c in 1:len
            if V[c] in same_colors[1]
                nb_new_violation[c] = 0
                for j in 1:instance.nb_HPRC
                    if instance.RC_flag[V[c], j]
                        last_ended_sequence = (position - instance.RC_q[j])
                        if last_ended_sequence > 0
                            nb_new_violation[c] += solution.M3[j, position-1] - solution.M3[j, last_ended_sequence]
                        else
                            nb_new_violation[c] += solution.M3[j, position-1]
                        end
                    end
                end
            end
        end

        # Compute the set of indices causing minimal-violation
        candidates = filter_on_min_criterion(V, nb_new_violation)

        # Two candidates or more - First tie break
        # If the average number of cars demanding a given option in the
        # partial sequence π is lower than that in the whole set V of vehicles,
        # then these cars should be encouraged to enter in the sequence.
        if length(candidates) > 1
            # Compute the tie break criterion for each candidates
            tie_break = zeros(Int, length(candidates))
            for i in 1:length(candidates)
                for j in 1:instance.nb_HPRC
                    cond1 = !instance.RC_flag[candidates[i],j]
                    cond2 = (rv[j]-rpi[j])/len > (rpi[j])/solution.length
                    tie_break[i] += Int(xor( cond1 , cond2 ))
                end
            end

            # Compute the new candidate list
            candidates = filter_on_max_criterion(candidates, tie_break)
        end

        # Two candidates or more - Second tie break
        # Cars that require options with higher utilization rates should enter.
        if length(candidates) > 1
            # Compute the utilization rate of each options
            utilization_rate = Array{Float64,1}(UndefInitializer(),instance.nb_HPRC)
            for j in 1:instance.nb_HPRC
                utilization_rate[j] = ( (rv[j] - rpi[j])/len ) / ( instance.RC_p[j] / instance.RC_q[j] )
            end
            tie_break = zeros(length(candidates))
            for i in 1:length(candidates)
                for j in 1:instance.nb_HPRC
                    tie_break[i] += instance.RC_flag[candidates[i],j] * utilization_rate[j]
                end
            end

            # Compute the new candidate list
            candidates = filter_on_max_criterion(candidates, tie_break)
        end

        # Two candidates or more - LPRC criterion
        # Choose the car that induces the smallest number of new violations of LPRC
        # when inserted at the end of the current partial sequence.
        if length(candidates) > 1
            # Compute the number of violations caused by each car
            nb_new_violation = zeros(Int, length(candidates))
            for ind in 1:length(candidates)
                c = candidates[ind]
                for j in (instance.nb_HPRC+1):(instance.nb_HPRC+instance.nb_LPRC)
                    if instance.RC_flag[c, j]
                        last_ended_sequence = (position - instance.RC_q[j])
                        if last_ended_sequence > 0
                            nb_new_violation[ind] += solution.M3[j, position-1] - solution.M3[j, last_ended_sequence]
                        else
                            nb_new_violation[ind] += solution.M3[j, position-1]
                        end
                    end
                end
            end
            candidates = filter_on_min_criterion(candidates, nb_new_violation)
        end

        c = rand(candidates)     # We have a valid candidate
        deleteat!(same_colors[1], findfirst(isequal(c), same_colors[1]))
        solution.sequence[position] = c
        solution.length += 1
        len = len - 1
        batch_size += 1
        if isempty(same_colors[1])
            batch_size = 0
            sort!(same_colors, by = x -> length(x), rev = true)
            pop!(same_colors)
        elseif batch_size == instance.nb_paint_limitation
            batch_size = 0
            sort!(same_colors, by = x -> length(x), rev = true)
            if instance.color_code[c] == instance.color_code[same_colors[1][1]]
                try
                    same_colors[1], same_colors[2] = copy(same_colors[2]), copy(same_colors[1])
                catch
                    position_car = instance.nb_late_prec_day+1
                    while instance.color_code[solution.sequence[position_car]] == instance.color_code[same_colors[1][1]]
                        position_car += 1
                    end
                    move_insertion!(solution, position_car, solution.length, instance)
                end
            end
        end
        filter!(x->x≠c, V)    # The car is not in the list anymore

        # The utilization rates components are dynamically updated.
        # Update rpi with the options of c
        for j in 1:instance.nb_HPRC
            rpi[j] += Int(instance.RC_flag[c,j])
        end

        # Update M1, M2 and M3
        update_matrices_new_car!(solution, position, instance)
    end

    @assert solution.length == instance.nb_cars

    if repair_needed
        initialize_batches!(solution, instance)
        second_strategy_repair!(solution, instance)
    end

    return solution
end
