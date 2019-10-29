




function greedy(inst::Instances)

# The constructive greedy heuristic starts with
# a partial sequence formed by the remaining cars
# from the previous day.

    # We compute an empty sequence with some cars already scheduled
    sol = init_solution(inst)
    # We have V the set of cars to be scheduled
    len = (sol.n) - (inst.nb_late_prec_day)
    V = collect((inst.nb_late_prec_day+1):(sol.n))

    # For the nb_late_prec_day first cars
    # Update M1, M2, M3
    for j in 1:inst.nb_HPRC
        # first sequence is compute wihout smart thoughts
        for i in 1:inst.HPRC_q[j]
            if inst.HPRC_flag[i,j] # if i has the option, M1 increments
                sol.M1[j,1] = sol.M1[j,1] + 1
            end
        end

        # First column of M2 and M3 can be update
        sol.M2[j,1] = (sol.M1[j,1] > inst.HPRC_p[j] ? 1 : 0)
        sol.M3[j,1] = (sol.M1[j,1] >= inst.HPRC_p[j] ? 1 : 0)

        # for each shift of sequence
        for i in 2:inst.nb_late_prec_day
            sol.M1[j,i] = sol.M1[j,i-1]

            # previous case had flag -> not in anymore
            if inst.HPRC_flag[i-1,j]
                sol.M1[j,i] = sol.M1[j,i] - 1
            end

            # new case has flag -> in now
            if inst.HPRC_flag[(i+inst.HPRC_q[j]-1),j]
                sol.M1[j,i] = sol.M1[j,i] + 1
            end

            # First column of M2 and M3 can be update
            sol.M2[j,i] = sol.M2[j,i-1] + (sol.M1[j,i] > inst.HPRC_p[j] ? 1 : 0)
            sol.M3[j,i] = sol.M3[j,i-1] + (sol.M1[j,i] >= inst.HPRC_p[j] ? 1 : 0)
        end

    end




    # The criterion consists in choosing, at each iteration, the car that
    # induces the smallest number of new violations when inserted at the
    # end of the current partial sequence.
    for pos in (inst.nb_late_prec_day+1):(sol.n)

        # I will now compute the number of violations caused by each car
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

        # I will now compute the set of minimal-rapist's indexes
        cars = [V[1]]
        nb_min = nb_new_violation[1]
        for c in 2:len
            if nb_new_violation[c] < nb_min
                nb_min = nb_new_violation[c]
                cars = [V[c]]
            elseif nb_new_violation[c] == nb_min
                push!(cars, V[c])
            end
        end

        # If |cars| =/= 1, we will pass by tie breaking criterion
        if length(cars) > 1

        end

        # The car is not in the list anymore
        c = cars[1]
        len = len - 1
        filter!(x->x≠c, V)

    end



    println(sol)

    return sol
end
