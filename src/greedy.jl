



function update_late_violation!(    sol::Solution,
                                    nb::Int,
                                    last::Int,
                                    p::Array{Int, 1},
                                    q::Array{Int, 1},
                                    flag::Array{Bool, 2},
                                    shift::Int=0           )

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

        # for each shift of sequence
        for i in 2:last
            sol.M1[J,i] = sol.M1[J,i-1]

            # previous case had flag -> not in anymore
            if flag[i-1,j]
                sol.M1[J,i] = sol.M1[J,i] - 1
            end

            # new case has flag -> in now
            if flag[(i+q[j]-1),j]
                sol.M1[J,i] = sol.M1[J,i] + 1
            end

            # First column of M2 and M3 can be update
            sol.M2[J,i] = sol.M2[J,i-1] + (sol.M1[J,i] >  p[j] ? 1 : 0)
            sol.M3[J,i] = sol.M3[J,i-1] + (sol.M1[J,i] >= p[j] ? 1 : 0)
        end
    end
end




function greedy(inst::Instances)

# The constructive greedy heuristic starts with
# a partial sequence formed by the remaining cars
# from the previous day.

    # We compute an empty sequence with some cars already scheduled
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

    return sol
end





#
# # LPRC's redundancy
#     # For the nb_late_prec_day first cars
#     # Update M1, M2, M3
#     for j in 1:inst.nb_LPRC
#         J = j + inst.nb_HPRC
#         # first sequence is compute wihout smart thoughts
#         for i in 1:inst.LPRC_q[j]
#             if inst.LPRC_flag[i,j] # if i has the option, M1 increments
#                 sol.M1[J,1] = sol.M1[J,1] + 1
#             end
#         end
#
#         # First column of M2 and M3 can be update
#         sol.M2[J,1] = (sol.M1[J,1] > inst.LPRC_p[j] ? 1 : 0)
#         sol.M3[J,1] = (sol.M1[J,1] >= inst.LPRC_p[j] ? 1 : 0)
#
#         # for each shift of sequence
#         for i in 2:inst.nb_late_prec_day
#             sol.M1[J,i] = sol.M1[J,i-1]
#
#             # previous case had flag -> not in anymore
#             if inst.LPRC_flag[i-1,j]
#                 sol.M1[J,i] = sol.M1[J,i] - 1
#             end
#
#             # new case has flag -> in now
#             if inst.LPRC_flag[(i+inst.LPRC_q[j]-1),j]
#                 sol.M1[J,i] = sol.M1[J,i] + 1
#             end
#
#             # First column of M2 and M3 can be update
#             sol.M2[J,i] = sol.M2[J,i-1] + (sol.M1[J,i] > inst.LPRC_p[j] ? 1 : 0)
#             sol.M3[J,i] = sol.M3[J,i-1] + (sol.M1[J,i] >= inst.LPRC_p[j] ? 1 : 0)
#         end
#     end
# # LRPC's end
