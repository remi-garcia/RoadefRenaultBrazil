#-------------------------------------------------------------------------------
# File: greedy.jl
# Description: This file contains all function used to construct
#         a first valid solution.
# Date: October 31, 2019
# Author: Jonathan Fontaine, Killian Fretaud, Rémi Garcia,
#         Boualem Lamraoui, Benoît Le Badezet, Benoit Loger
#-------------------------------------------------------------------------------


"""
    update_late_violation!(solution::Solution, nb::Int, last::Int,
                           p::Array{Int, 1}, q::Array{Int, 1},
                           flag::Array{Bool, 2}, shift::Int = 0)

Update `solution.M1`, `solution.M2` and `solution.M3` with cars from the day
before. `shift` parameter is used for LPRC.
"""
function update_late_violation!(solution::Solution, nb::Int, last::Int,
                                p::Array{Int, 1}, q::Array{Int, 1},
                                flag::Array{Bool, 2}, shift::Int = 0)
    @warn "Function update_late_violation! deprecated -> call functions in solution.jl"
    # Update M1, M2 and M3 for the first car
    for j in 1:nb
        J = j + shift
        for i in 1:q[j]
            if flag[i,j]
                solution.M1[J,1] = solution.M1[J,1] + 1
            end
        end
        # First column of M2 and M3 can be update
        solution.M2[J,1] = (solution.M1[J,1] >  p[j] ? 1 : 0)
        solution.M3[J,1] = (solution.M1[J,1] >= p[j] ? 1 : 0)
    end

    update_solution!(solution, nb, 2, last, p, q, flag, shift)
    return solution
end

"""
    update_solution!(solution::Solution, nb::Int, first::Int, last::Int,
                     p::Array{Int, 1}, q::Array{Int, 1},
                     flag::Array{Bool, 2}, shift::Int = 0)

Update `solution.M1`, `solution.M2` and `solution.M3` with cars from the day
before. The first column has already been updated in `update_late_violation!()`.
`shift` parameter is used for LPRC.
"""
function update_solution!(solution::Solution, nb::Int, first::Int, last::Int,
                          p::Array{Int, 1}, q::Array{Int, 1},
                          flag::Array{Bool, 2}, shift::Int = 0)
    @warn "Function update_solution! deprecated -> call functions in solution.jl"
    for j in 1:nb
        J = j + shift
        # for each shift of sequences
        for i in first:last
            solution.M1[J, i] = solution.M1[J, i-1]
            # previous case had flag -> not in anymore
            I = solution.sequence[i-1]
            if flag[I,j]
                solution.M1[J, i] = solution.M1[J, i] - 1
            end
            # new case has flag -> in now
            if (i+q[j]-1) <= last
                I = solution.sequence[(i+q[j])-1]
                if flag[I, j]
                    solution.M1[J, i] = solution.M1[J, i] + 1
                end
            end
            # First column of M2 and M3 can be update
            solution.M2[J, i] = solution.M2[J, i-1] + (solution.M1[J, i] >  p[j] ? 1 : 0)
            solution.M3[J, i] = solution.M3[J, i-1] + (solution.M1[J, i] >= p[j] ? 1 : 0)
        end
    end

    return solution
end

"""
    update_solution_at!(solution::Solution, nb::Int, pos::Int,
                        p::Array{Int, 1}, q::Array{Int, 1},
                        flag::Array{Bool, 2}, shift::Int = 0)

Update column `pos` of `solution.M1`, `solution.M2` and `solution.M3`. `shift`
parameter is used for LPRC.
"""
function update_solution_at!(solution::Solution, nb::Int, pos::Int,
                           p::Array{Int, 1}, q::Array{Int, 1},
                           flag::Array{Bool, 2}, shift::Int = 0)
    @warn "Function update_solution_at! deprecated -> call functions in solution.jl"
    for j in 1:nb
        J = j + shift
        # for each shift of sequence reaching this position
        I = solution.sequence[pos]
        for i in (pos - q[j] + 1):pos
            # new car has option j -> update M1
            if flag[I, j]
                solution.M1[J, i] = solution.M1[J, i] + 1
            end
            # First column of M2 and M3 can be update
            if i == 1
                solution.M2[J, i] = 0 + (solution.M1[J, i] >  p[j] ? 1 : 0)
                solution.M3[J, i] = 0 + (solution.M1[J, i] >= p[j] ? 1 : 0)
            else
                solution.M2[J, i] = solution.M2[J, i-1] + (solution.M1[J, i] >  p[j] ? 1 : 0)
                solution.M3[J, i] = solution.M3[J, i-1] + (solution.M1[J, i] >= p[j] ? 1 : 0)
            end
        end
    end

    return solution
end

##===================================================##
##                 Greedy algorithm                  ##
##===================================================##

"""
    filter_on_max_criterion!(candidates::Array{Int64,1}, criterion)

Takes a set of candidates and removes all elements with bad criterion.
"""
function filter_on_max_criterion(candidates::Array{Int64,1}, criterion) # TODO: criterion is Int or Float
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
    #candidates = tmp_candidates
    return tmp_candidates
end

"""
    filter_on_min_criterion!(candidates::Array{Int64,1}, criterion)

Takes a set of candidates and removes all elements with bad criterion.
"""
function filter_on_min_criterion(candidates::Array{Int64,1}, criterion) # TODO: criterion is Int or Float
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
    #candidates = tmp_candidates
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
    len = (solution.n) - (instance.nb_late_prec_day)
    V = collect((instance.nb_late_prec_day+1):(solution.n))

    # Compute for each option the number of cars who need it in V
    # TODO : Could be done in the parser and stocked in the instance
    rv = sum(instance.RC_flag,dims=1)

    # For the nb_late_prec_day first cars, update M1, M2, M3
    update_matrices!(solution, instance.nb_late_prec_day, instance)

    # Initialization for first tie-break criterion
    # Compute for each option the number of cars who need it in Pi
    length_pi = instance.nb_late_prec_day
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
    for position in (instance.nb_late_prec_day+1):(solution.n)
        # Compute the number of violations caused by each car
        nb_new_violation = zeros(Int, len)
        for c in 1:len
            for j in 1:instance.nb_HPRC
                if instance.RC_flag[V[c], j]
                    for i in ((position - instance.RC_q[j])+1):position
                        if solution.M1[j, i] >= instance.RC_p[j]
                            nb_new_violation[c] = nb_new_violation[c] + 1
                        end
                    end
                end
            end
        end

        # Compute the set of indexes causing minimal-violation
        candidates = filter_on_min_criterion(V, nb_new_violation)

        # Two candidates or more - First tie break
        # If the average number of cars demanding a given option in the
        # partial sequence π is lower than that in the whole set V of vehicles,
        # then these cars should be encouraged to enter in the sequence.
        if length(candidates) > 1
            # Compute the tie break criterion for each candidates
            tie_break = zeros(Int,length(candidates))
            for i in 1:length(candidates)
                for j in 1:instance.nb_HPRC
                    cond1 = !instance.RC_flag[candidates[i],j]
                    cond2 = (rv[j]-rpi[j])/len > (rpi[j])/length_pi
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
                        for i in ((position - instance.RC_q[j])+1):position
                            if solution.M1[j, i] >= instance.RC_p[j]
                                nb_new_violation[ind] = nb_new_violation[ind] + 1
                            end
                        end
                    end
                end
            end
            candidates = filter_on_min_criterion(candidates, nb_new_violation)
        end

        c = rand(candidates)     # We have a valid candidate
        solution.sequence[position] = c
        len = len - 1
        length_pi = length_pi + 1
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
