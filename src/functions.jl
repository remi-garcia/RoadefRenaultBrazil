#=
# This file contains functions that are used in VNS and ILS.
#
# @Author Boualem Lamraoui, Benoît Le Badezet, Benoit Loger, Jonathan Fontaine, Killian Fretaud, Rémi Garcia
# =#
"""
    move_exchange!(solution::Solution, i::Int, j::Int, instance::instances)

Interverts the car `i` with the car `j` in `solution.sequence`. Updates
`solution.M1`, `solution.M2` and `solution.M3`.
"""
<<<<<<< HEAD
function move_exchange!(solution::Solution,i::Int,j::Int, instance::Instances)
    sol_i = solution.sequence[ i ]
    solution.sequence[ i ] = solution.sequence[ j ]
    solution.sequence[ j ] = sol_i
    for k in 1 : instance.nb_HPRC + instance.nb_LPRC
        if k <= instance.nb_HPRC
            if instance.HPRC_flag[ i , k ] == false && instance.HPRC_flag[ j , k ] == true
                pos1 = i - ( instance.HPRC_q[ k ]-1)
                for l in pos1 : i
                    solution.M1[ k , l ] += 1
                end
                pos2 = j - (instance.HPRC_q[ k ]-1)
                for l in pos2 : j
                    solution.M1[ k , l ] -= 1
                end
                cpt1 = solution.M2[ k , pos1 - 1]
                cpt2 = solution.M3[ k , pos1 - 1 ]
                for l in pos1 : solution.n
                    if solution.M1[ k , l ] > instance.HPRC_p[ k ]
                        cpt1 += 1
                        solution.M2[ k , l ] = cpt1
                    else
                        solution.M2[ k , l ] = cpt1
                    end
                    if solution.M1[ k , l ] >= instance.HPRC_p[ k ]
                        cpt2 += 1
                        solution.M3[ k , l ] = cpt2
                    else
                        solution.M3[ k , l ] = cpt2
                    end
                end
            end
            if instance.HPRC_flag[ i , k ] == true && instance.HPRC_flag[ j , k ] == false
               pos1 = i - (instance.HPRC_q[ k ] - 1)
               for l in pos1 : i
                   solution.M1[ k , l ] -= 1
               end
               pos2 = j - (instance.HPRC_q[ k ]-1)
               for l in pos2 : j
                   solution.M1[ k , l ] += 1
               end
               cpt1 = solution.M2[ k , pos1 - 1]
               cpt2 = solution.M3[ k , pos1 - 1 ]
               for l in pos1 : solution.n
                   if solution.M1[ k , l ] > instance.HPRC_p[ k ]
                       cpt1 += 1
                       solution.M2[ k , l ] = cpt1
                   else
                       solution.M2[ k , l ] = cpt1
                   end
                   if solution.M1[ k , l ] >= instance.HPRC_p[ k ]
                       cpt2 += 1
                       solution.M3[ k , l ] = cpt2
                   else
                       solution.M3[ k , l ] = cpt2
                   end
               end
            end
        else
            if instance.LPRC_flag[ i , k - instance.HPRC_q[ k ] ] == false && instance.LPRC_flag[ j , k - instance.HPRC_q[ k ] ] == true
                pos1 = i - ( instance.LPRC_q[ k - instance.HPRC_q[ k ] ]-1)
                for l in pos1 : i
                    solution.M1[ k , l ] += 1
                end
                pos2 = j - (instance.LPRC_q[ k - instance.HPRC_q[ k ] ]-1)
                for l in pos2 : j
                    solution.M1[ k , l ] -= 1
                end
                cpt1 = solution.M2[ k , pos1 - 1]
                cpt2 = solution.M3[ k , pos1 - 1 ]
                for l in pos1 : solution.n
                    if solution.M1[ k , l ] > instance.LPRC_p[ k - instance.HPRC_q[ k ]  ]
                        cpt1 += 1
                        solution.M2[ k , l ] = cpt1
                    else
                        solution.M2[ k , l ] = cpt1
                    end
                    if solution.M1[ k , l ] >= instance.LPRC_p[ k - instance.HPRC_q[ k ]  ]
                        cpt2 += 1
                        solution.M3[ k , l ] = cpt2
                    else
                        solution.M3[ k , l ] = cpt2
                    end
                end
            end
            if instance.LPRC_flag[ i , k - instance.HPRC_q[ k ] ] == true && instance.LPRC_flag[ j , k - instance.HPRC_q[ k ] ] == false
               pos1 = i - (instance.LPRC_q[ k - instance.HPRC_q[ k ] ] - 1)
               for l in pos1 : i
                   solution.M1[ k , l ] -= 1
               end
               pos2 = j - (instance.LPRC_q[ k - instance.HPRC_q[ k ] ]-1)
               for l in pos2 : j
                   solution.M1[ k , l ] += 1
               end
               cpt1 = solution.M2[ k , pos1 - 1]
               cpt2 = solution.M3[ k , pos1 - 1 ]
               for l in pos1 : solution.n
                   if solution.M1[ k , l ] > instance.LPRC_p[ k - instance.HPRC_q[ k ]  ]
                       cpt1 += 1
                       solution.M2[ k , l ] = cpt1
                   else
                       solution.M2[ k , l ] = cpt1
                   end
                   if solution.M1[ k , l ] >= instance.LPRC_p[ k - instance.HPRC_q[ k ] ]
                       cpt2 += 1
                       solution.M3[ k , l ] = cpt2
                   else
                       solution.M3[ k , l ] = cpt2
                   end
               end
            end
=======
function move_exchange!(solution::Solution,i::Int,j::Int, instance::instances)
    sol_i = solution.sequence[i]
    solution.sequence[i] = solution.sequence[j]
    solution.sequence[j] = sol_i
    for k in 1:instance.nb_HPRC + instancek.nb_LPRC
        if <= instance.nb_HPRC
            if instance.HPRC_flag[i,k] == false && instance.HPRC_flag[j,k] == true
                pos1 = i - ( instance.HPRC_q[k]-1 )
                for l in pos1:i
                    solution.M1[k,l] += 1
                end
                pos2 = j - (instance.HPRC_q[k]-1)
                for l in pos2:i
                    solution.M1[k,l] -= 1
                end
                cpt = solution.M2[k,pos1-1]
                for l in pos1:solution.n
                    if solution.M1[k,l] > instance.HPRC_p[k]
                        cpt += 1
                        solution.M2[k,l] = cpt
                    else
                        solution.M2[k,l] = cpt
                    end
                    if solution.M1[k,l] >= instance.HPRC_p[k]
                        cpt += 1
                        solution.M3[k,l] = cpt
                    else
                        solution.M3[k,l] = cpt
                    end
                end
            else
                if instance.HPRC_flag[i,k] == true && instance.HPRC_flag[j,k] == false
                    pos1 = i-(instance.HPRC_q[k]-1)
                    for l in pos1:i
                        solution.M1[k,l] -= 1
                    end
                    pos2 = j-(instance.HPRC_q[k]-1)
                    for l in pos2:i
                        solution.M1[k,l] += 1
                    end
                    cpt = solution.M2[k,pos1-1]
                    for l in pos1:solution.n
                        if solution.M1[k,l] > instance.HPRC_p[k]
                            cpt += 1
                            solution.M2[k,l] = cpt
                        else
                            solution.M2[k,l] = cpt
                        end
                        if solution.M1[k,l] >= instance.HPRC_p[k]
                            cpt += 1
                            solution.M3[k,l] = cpt
                        else
                            solution.M3[k,l] = cpt
                        end
                    end
                end
            end
            #else On ne fait rien
        else
            if instance.LPRC_flag[i,k-instace.nb_HPRC] == false && instance.LPRC_flag[j,k-instace.nb_HPRC] == true
                pos1 = i - ( instance.LPRC_q[k-instace.nb_HPRC]-1 )
                for l in pos1:i
                    solution.M1[k,l] += 1
                end
                pos2 = j - (instance.LPRC_q[k-instace.nb_HPRC]-1)
                for l in pos2:i
                    solution.M1[k,l] -= 1
                end
                cpt = solution.M2[k,pos1-1]
                for l in pos1:solution.n
                    if solution.M1[k,l] > instance.LPRC_p[k-instace.nb_HPRC]
                        cpt += 1
                        solution.M2[k,l] = cpt
                    else
                        solution.M2[k,l] = cpt
                    end
                    if solution.M1[k,l] >= instance.LPRC_p[k-instace.nb_HPRC]
                        cpt += 1
                        solution.M3[k,l] = cpt
                    else
                        solution.M3[k,l] = cpt
                    end
                end
            else
                if instance.LPRC_flag[i,k-instace.nb_HPRC] == true && instance.LPRC_flag[j,k-instace.nb_HPRC] == false
                    pos1 = i-(instance.LPRC_q[k-instace.nb_HPRC]-1)
                    for l in pos1:i
                        solution.M1[k,l] -= 1
                    end
                    pos2 = j-(instance.LPRC_q[k-instace.nb_HPRC]-1)
                    for l in pos2:i
                        solution.M1[k,l] += 1
                    end
                    cpt = solution.M2[k,pos1-1]
                    for l in pos1:solution.n
                        if solution.M1[k,l] > instance.LPRC_p[k-instace.nb_HPRC]
                            cpt += 1
                            solution.M2[k,l] = cpt
                        else
                            solution.M2[k,l] = cpt
                        end
                        if solution.M1[k,l] >= instance.LPRC_p[k-instace.nb_HPRC]
                            cpt += 1
                            solution.M3[k,l] = cpt
                        else
                            solution.M3[k,l] = cpt
                        end
                    end
                end
            end
            #else On ne fait rien
>>>>>>> e96f5e8dc317d981cb365950ac40d4eaa7cd0e9d
        end
    end
    return solution
end

"""
<<<<<<< HEAD
    move_insertion!(solution::Solution, i::Int, j::Int, instance::Instances)
=======
    move_insertion!(solution::Solution, i::Int, j::Int, instanceance::instanceances)
>>>>>>> e96f5e8dc317d981cb365950ac40d4eaa7cd0e9d

Inserts the car `i` before the car `j` in `solution.sequence`. Updates
`solution.M1`, `solution.M2` and `solution.M3`.
"""
<<<<<<< HEAD
function move_insertion!(solution::Solution, i::Int, j::Int, instance::Instances)
=======
function move_insertion!(solution::Solution, i::Int, j::Int, instanceance::instanceances)
>>>>>>> e96f5e8dc317d981cb365950ac40d4eaa7cd0e9d
    # TODO
    return Solution
end

"""
    cost_move_exchange(solution::Solution, i::Int, j::Int,
<<<<<<< HEAD
                       instance::Instances, objective::Int)
=======
                       instanceance::instanceances, objective::Int)
>>>>>>> e96f5e8dc317d981cb365950ac40d4eaa7cd0e9d

Return the cost of the exchange of the car `i` with the car `j` with respect to
objective `objective`. A negative cost means that the move is interesting with
respect to objective `objective`.
"""
function cost_move_exchange(solution::Solution, i::Int, j::Int,
<<<<<<< HEAD
                            instance::Instances, objective::Int)
=======
                            instanceance::instanceances, objective::Int)
>>>>>>> e96f5e8dc317d981cb365950ac40d4eaa7cd0e9d
    #TODO it might be important that objective is a vector of Int, then we could
    #return a vector of cost.

    # objective should take values between 1 and 3.
    @assert objective >= 1
    @assert objective <= 3
    # TODO
    return 0
end

"""
    cost_move_insertion(solution::Solution, i::Int, j::Int,
<<<<<<< HEAD
                        instance::Instances, objective::Int)
=======
                        instanceance::instanceances, objective::Int)
>>>>>>> e96f5e8dc317d981cb365950ac40d4eaa7cd0e9d

Return the cost of the insertion of the car `i` before the car `j` with respect
to objective `objective`. A negative cost means that the move is interesting
with respect to objective `objective`.
"""
function cost_move_insertion(solution::Solution, i::Int, j::Int,
<<<<<<< HEAD
                             instance::Instances, objective::Int)
=======
                             instanceance::instanceances, objective::Int)
>>>>>>> e96f5e8dc317d981cb365950ac40d4eaa7cd0e9d
    #TODO it might be important that objective is a vector of Int, then we could
    #return a vector of cost.

    # objective should take values between 1 and 3.
    @assert objective >= 1
    @assert objective <= 3
    # TODO
    return 0
end
