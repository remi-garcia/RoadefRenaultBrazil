#=
This file contains all function used to construct a first valid solution.
=#

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

        update_solution!(solution, nb, 2, last, p, q, flag, shift)
    end

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

"""
    greedy(inst::Instances)

Takes an `Instance` and return a valid `Solution`.
"""
function greedy(inst::Instances)
    # The constructive greedy heuristic starts with a partial sequence formed
    # by the remaining cars from the previous day. We compute an empty sequence
    # with some cars already scheduled
    solution = init_solution(inst)
    # We have V the set of cars to be scheduled
    len = (solution.n) - (inst.nb_late_prec_day)
    V = collect((inst.nb_late_prec_day+1):(solution.n))
    nbH = inst.nb_HPRC

    # Compute for each option the number of cars who need it in V
    # This should probably be done directly in the parser and stocked in
    # the instance
    rv = sum(inst.HPRC_flag,dims=1)

    # For the nb_late_prec_day first cars
    # Update M1, M2, M3
    #TODO: clean parameters
    update_late_violation!(solution, inst.nb_HPRC, inst.nb_late_prec_day, inst.HPRC_p, inst.HPRC_q, inst.HPRC_flag)
    update_late_violation!(solution, inst.nb_LPRC, inst.nb_late_prec_day, inst.LPRC_p, inst.LPRC_q, inst.LPRC_flag, inst.nb_HPRC)

    # Compute for each option the number of cars who need it in Pi
    length_pi = inst.nb_late_prec_day
    rpi = zeros(Int,nbH)
    for j in 1:nbH
        for i in 1:inst.nb_late_prec_day
            if inst.HPRC_flag[i,j]
                rpi[j] = rpi[j]+1
            end
        end
    end

    # The greedy criterion consists in choosing, at each iteration, the car
    # that induces the smallest number of new violations when inserted at
    # the end of the current partial sequence.
    for pos in (inst.nb_late_prec_day+1):(solution.n)
        # Compute the number of violations caused by each car
        nb_new_violation = zeros(Int, len)
        for c in 1:len
            for j in 1:inst.nb_HPRC
                if inst.HPRC_flag[V[c], j]
                    for i in ((pos - inst.HPRC_q[j])+1):pos
                        if solution.M1[j, i] >= inst.HPRC_p[j]
                            nb_new_violation[c] = nb_new_violation[c] + 1
                        end
                    end
                end
            end
        end

        # Compute the set of indexes causing minimal-violation
        candidates = [V[1]]
        nb_min = nb_new_violation[1]
        for c in 2:len
            if nb_new_violation[c] < nb_min
                nb_min = nb_new_violation[c]
                candidates = [V[c]]
            elseif nb_new_violation[c] == nb_min
                push!(candidates, V[c])
            end
        end

        # If |candidates| =/= 1 : TIE BREAK
        #
        # We will pass by tie breaking criterion
        # This criterion encourages a more homogeneous distribution of
        # the required options among the cars already in the partial sequence
        # and those still to be scheduled.
        # The distribution is based on the following idea:
        #
        #   If the average number of cars demanding a given option in the
        #   partial sequence p is lower than that in the whole set V of
        #   vehicles, then these cars should be encouraged to enter in
        #   the sequence.
        #
        if length(candidates) > 1
            # Compute the tie break criterion for each candidates
            tie_break = zeros(Int,length(candidates))
            for i in 1:length(candidates)
                for j in 1:nbH
                    cond1 = !inst.HPRC_flag[candidates[i],j]
                    cond2 = (rv[j]-rpi[j])/len > (rpi[j])/length_pi
                    tie_break[i] += Int(xor( cond1 , cond2 ))
                end
            end

            # Compute the new candidate list
            tmp_candidates = copy(candidates)
            candidates = [tmp_candidates[1]]
            max_tie_break = tie_break[1]
            for i in 2:length(tmp_candidates)
              if tie_break[i] > max_tie_break
                  candidates = [tmp_candidates[i]]
                  max_tie_break = tie_break[i]
              elseif tie_break[i] == max_tie_break
                  push!(candidates, tmp_candidates[i])
              end
            end
        end

        # If |candidates| =/= 1 : DOUBLE TIE BREAK
        #
        # It may happen that ties still remain after the application of
        # the above tie breaking criterion. In this case, a second criterion
        # is added, favoring cars that require options with higher
        # utilization rates. The utilization rates are dynamically computed,
        # in the sense that they are updated whenever a new car is added at
        # the end of the sequence.
        if length(candidates) > 1
            #TODO
        end

        c = candidates[1]     # We have a valid candidate
        solution.sequence[pos] = c
        len = len - 1
        length_pi = length_pi - 1
        filter!(x->x≠c, V)    # The car is not in the list anymore

        # Update M1, M2 and M3
        update_solution_at!(solution, inst.nb_HPRC, pos, inst.HPRC_p, inst.HPRC_q, inst.HPRC_flag)
        update_solution_at!(solution, inst.nb_LPRC, pos, inst.LPRC_p, inst.LPRC_q, inst.LPRC_flag, inst.nb_HPRC)
    end


    return solution
end
