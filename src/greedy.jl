#=
This file contains all function used to construct a first valid solution.
=#


function update_late_violation!(    sol::Solution,
                                    nb::Int, # number of options treated
                                    last::Int,
                                    p::Array{Int, 1}, q::Array{Int, 1},
                                    flag::Array{Bool, 2},
                                    shift::Int=0   #= for LPRC =#       )
    # For the nb_late_prec_day first cars
    # Update M1, M2, M3
    for j in 1:nb
        J = j + shift

        # first sequence is compute wihout smart thoughts
        for i in 1:q[j]
            if flag[i,j] # if i has the option, M1 increments
                sol.M1[J,1] = sol.M1[J,1] + 1
            end
        end
        # First column of M2 and M3 can be update
        sol.M2[J,1] = (sol.M1[J,1] >  p[j] ? 1 : 0)
        sol.M3[J,1] = (sol.M1[J,1] >= p[j] ? 1 : 0)

        update_sol!(sol, nb, 2, last, p, q, flag, shift)
    end
end


# Parameter "first" seems now useless, I thought it would allow us to use the
# function during the next phase (updating solution after pushing a new car)
function update_sol!(   sol::Solution,
                        nb::Int, # number of options treated
                        first::Int, last::Int,
                        p::Array{Int, 1}, q::Array{Int, 1},
                        flag::Array{Bool, 2},
                        shift::Int=0  #= for LPRC =#          )
    for j in 1:nb
        J = j + shift
        # for each shift of sequences
        for i in first:last
            sol.M1[J,i] = sol.M1[J,i-1]

            # previous case had flag -> not in anymore
            I = sol.sequence[i-1]
            if flag[I,j]
                sol.M1[J,i] = sol.M1[J,i] - 1
            end

            # new case has flag -> in now
            if (i+q[j]-1) <= last
                I = sol.sequence[(i+q[j])-1]
                if flag[I,j]
                    sol.M1[J,i] = sol.M1[J,i] + 1
                end
            end

            # First column of M2 and M3 can be update
            sol.M2[J,i] = sol.M2[J,i-1] + (sol.M1[J,i] >  p[j] ? 1 : 0)
            sol.M3[J,i] = sol.M3[J,i-1] + (sol.M1[J,i] >= p[j] ? 1 : 0)
        end
    end
end


function update_sol_atpos!( sol::Solution,
                            nb::Int,
                            pos::Int,
                            p::Array{Int, 1}, q::Array{Int, 1},
                            flag::Array{Bool, 2},
                            shift::Int=0                        )
    for j in 1:nb
        J = j + shift
        # for each shift of sequence reaching this position
        I = sol.sequence[pos]
        for i in (pos - q[j] + 1):pos

            # new car has option j -> update M1
            if flag[I,j]
                sol.M1[J,i] = sol.M1[J,i] + 1
            end

            # First column of M2 and M3 can be update
            if i == 1
                sol.M2[J,i] = 0 + (sol.M1[J,i] >  p[j] ? 1 : 0)
                sol.M3[J,i] = 0 + (sol.M1[J,i] >= p[j] ? 1 : 0)
            else
                sol.M2[J,i] = sol.M2[J,i-1] + (sol.M1[J,i] >  p[j] ? 1 : 0)
                sol.M3[J,i] = sol.M3[J,i-1] + (sol.M1[J,i] >= p[j] ? 1 : 0)
            end
        end
    end
end


function greedy(inst::Instances)
    # The constructive greedy heuristic starts with a partial sequence formed
    # by the remaining cars from the previous day. We compute an empty sequence
    # with some cars already scheduled
    sol = init_solution(inst)
    # We have V the set of cars to be scheduled
    len = (sol.n) - (inst.nb_late_prec_day)
    V = collect((inst.nb_late_prec_day+1):(sol.n))
    nbH = inst.nb_HPRC

    # For the nb_late_prec_day first cars
    # Update M1, M2, M3
    # TODO: clean parameters
    update_late_violation!(sol, inst.nb_HPRC, inst.nb_late_prec_day, inst.HPRC_p, inst.HPRC_q, inst.HPRC_flag)
    update_late_violation!(sol, inst.nb_LPRC, inst.nb_late_prec_day, inst.LPRC_p, inst.LPRC_q, inst.LPRC_flag, inst.nb_HPRC)

    # The greedy criterion consists in choosing, at each iteration, the car
    # that induces the smallest number of new violations when inserted at
    # the end of the current partial sequence.
    for pos in (inst.nb_late_prec_day+1):(sol.n)

        # Compute the number of violations caused by each car
        nb_new_violation = zeros(Int, len)
        for c in 1:len
            for j in 1:inst.nb_HPRC
                if inst.HPRC_flag[V[c],j]
                    for i in ((pos - inst.HPRC_q[j])+1):pos
                        if sol.M1[j,i] >= inst.HPRC_p[j]
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
            #TODO
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
        sol.sequence[pos] = c
        len = len - 1
        filter!(x->x≠c, V)    # The car is not in the list anymore

        # Update M1, M2 and M3
        update_sol_atpos!(sol, inst.nb_HPRC, pos, inst.HPRC_p, inst.HPRC_q, inst.HPRC_flag)
        update_sol_atpos!(sol, inst.nb_LPRC, pos, inst.LPRC_p, inst.LPRC_q, inst.LPRC_flag, inst.nb_HPRC)
    end

    return sol
end