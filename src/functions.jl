#=
# This file contains functions that are used in VNS and ILS.
#
# @Author Boualem Lamraoui, Benoît Le Badezet, Benoit Loger, Jonathan Fontaine, Killian Fretaud, Rémi Garcia
# =#

include("solution.jl")
include("parser.jl")
"""
    move_exchange!(solution::Solution, i::Int, j::Int, instance::Instances)

Interverts the car `i` with the car `j` in `solution.sequence`. Updates
`solution.M1`, `solution.M2` and `solution.M3`.
"""
function move_exchange!(solution::Solution,i::Int,j::Int, instance::Instances)
    sol_i=solution.sequence[i]
    solution.sequence[i]=solution.sequence[j]
    solution.sequence[j]=sol_i
    for k in 1:inst.nb_HPRC
        if inst.HPRC_flag[i,k]==false && inst.HPRC_flag[j,k]==true
            pos1=i-(inst.HPRC_q[k]-1)
            for l in pos1:i
                solution.M1[k,l]+=1
            end
            pos2=j-(inst.HPRC_q[k]-1)
            for l in pos2:i
                solution.M1[k,l]-=1
            end
            cpt=solution.M2[k,pos1-1]
            for l in pos1:solution.n
                if solution.M1[k,l]>inst.HPRC_p[k]
                    cpt+=1
                    solution.M2[k,l]=cpt
                else
                    solution.M2[k,l]=cpt
                end
                if solution.M1[k,l]>=inst.HPRC_p[k]
                    cpt+=1
                    solution.M3[k,l]=cpt
                else
                    solution.M3[k,l]=cpt
                end
            end
        else
            if inst.HPRC_flag[i,k]==true && inst.HPRC_flag[j,k]==false
                pos1=i-(inst.HPRC_q[k]-1)
                for l in pos1:i
                    solution.M1[k,l]-=1
                end
                pos2=j-(inst.HPRC_q[k]-1)
                for l in pos2:i
                    solution.M1[k,l]+=1
                end
                cpt=solution.M2[k,pos1-1]
                for l in pos1:solution.n
                    if solution.M1[k,l]>inst.HPRC_p[k]
                        cpt+=1
                        solution.M2[k,l]=cpt
                    else
                        solution.M2[k,l]=cpt
                    end
                    if solution.M1[k,l]>=inst.HPRC_p[k]
                        cpt+=1
                        solution.M3[k,l]=cpt
                    else
                        solution.M3[k,l]=cpt
                    end
                end
            end
        end
        #else On ne fait rien
    end
    return solution
end

"""
    move_insertion!(solution::Solution, i::Int, j::Int, instance::Instances)

Inserts the car `i` before the car `j` in `solution.sequence`. Updates
`solution.M1`, `solution.M2` and `solution.M3`.
"""
function move_insertion!(solution::Solution, i::Int, j::Int, instance::Instances)
    # TODO
    return Solution
end

"""
    cost_move_exchange(solution::Solution, i::Int, j::Int,
                       instance::Instances, objective::Int)

Return the cost of the exchange of the car `i` with the car `j` with respect to
objective `objective`. A negative cost means that the move is interesting with
respect to objective `objective`.
"""
function cost_move_exchange(solution::Solution, i::Int, j::Int,
                            instance::Instances, objective::Int)
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
                        instance::Instances, objective::Int)

Return the cost of the insertion of the car `i` before the car `j` with respect
to objective `objective`. A negative cost means that the move is interesting
with respect to objective `objective`.
"""
function cost_move_insertion(solution::Solution, i::Int, j::Int,
                             instance::Instances, objective::Int)
    #TODO it might be important that objective is a vector of Int, then we could
    #return a vector of cost.

    # objective should take values between 1 and 3.
    @assert objective >= 1
    @assert objective <= 3
    # TODO
    return 0
end
