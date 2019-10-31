#=
# This file has to purpose to have functions that are used in different algorithm.
#
# @Author Boualem Lamraoui, Benoît Le Badezet, Benoit Loger, Jonathan Fontaine, Killian Fretaud, Rémi Garcia
# =#

include("solution.jl")
include("parser.jl")
function move_exchange(pi::Solution,i::Int,j::Int, instance::Instances)
    for k in 1:inst.nb_HPRC
        if inst.HPRC_flag[i,k]==false && inst.HPRC_flag[j,k]==true
            pos1=i-(inst.HPRC_q[k]-1)
            for l in pos1:i
                pi.M1[k,l]+=1
            end
            pos2=j-(inst.HPRC_q[k]-1)
            for l in pos2:i
                pi.M1[k,l]-=1
            end
            cpt=pi.M2[k,pos1-1]
            for l in pos1:pi.n
                if pi.M1[k,l]>inst.HPRC_p[k]
                    cpt+=1
                    pi.M2[k,l]=cpt
                else
                    pi.M2[k,l]=cpt
                end
                if pi.M1[k,l]>=inst.HPRC_p[k]
                    cpt+=1
                    pi.M3[k,l]=cpt
                else
                    pi.M3[k,l]=cpt
                end
            end
        else
            if inst.HPRC_flag[i,k]==true && inst.HPRC_flag[j,k]==false
                pos1=i-(inst.HPRC_q[k]-1)
                for l in pos1:i
                    pi.M1[k,l]-=1
                end
                pos2=j-(inst.HPRC_q[k]-1)
                for l in pos2:i
                    pi.M1[k,l]+=1
                end
                cpt=pi.M2[k,pos1-1]
                for l in pos1:pi.n
                    if pi.M1[k,l]>inst.HPRC_p[k]
                        cpt+=1
                        pi.M2[k,l]=cpt
                    else
                        pi.M2[k,l]=cpt
                    end
                    if pi.M1[k,l]>=inst.HPRC_p[k]
                        cpt+=1
                        pi.M3[k,l]=cpt
                    else
                        pi.M3[k,l]=cpt
                    end
                end
            end
        end
        #else On ne fait rien
    end
    return pi
end

function move_insertion(solution::Solution, i::Int, j::Int, instance::Instances)
    # TODO
    return Solution(1,1)
end
