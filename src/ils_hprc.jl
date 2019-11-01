#=
# ILS_HRPC for the RENAULT Roadef 2005 challenge
# inspired by work of
# Celso C. Ribeiro, Daniel Aloise, Thiago F. Noronha, Caroline Rocha, Sebastián Urrutia
#
# @Author Boualem Lamraoui, Benoît Le Badezet, Benoit Loger, Jonathan Fontaine, Killian Fretaud, Rémi Garcia
# =#




##=====================================##
##        USEFUL ALGORITHMS            ##
##=====================================##

function perturbation(s::Solution, inst::Instance)
    #TODO
    return s
end

# Retourne le coût du premier objectif pour la solution s
function costHPRC(s::Solution, inst::Instance)
    c = sum(s.M2[i, s.n] for i in 1:inst.nb_HPRC)
    return c
end


function localSearch(s::Solution, inst::Instance)
    while true
        phi = costHPRC(s, inst)
        b0 = inst.nb_late_prec_day + 1      #First car of the current production day
        for i in b0:s.n
            best_delta = 0
            L = []
            for j in b0:s.n
                delta = costHPRC(move(s, i, j), inst) - costHPRC(s, inst)
                if delta < best_delta
                    L = [j]
                    best_delta = delta
                elseif delta == best_delta
                    push!(L, j)
                end
            end
            if L != []
                k = rand(L)
                s = move(s, i, k)
            end
        end
        if phi == costHPRC(s)
            break
        end
    end

    return s
end

function fastLocalSearch(s::Solution, inst::Instance, crit::Array{Int, 1})
    #TODO
    return s
end

#Inidquate which cars are invloved in violation of HPRC and the number
function criticalCars(s::Solution, inst::Instance)
    criticars = zeros(Int, s.n)             # criticars[i] = 1 if car i violate HPRC otherwhise criticars[i] = 0
    nb_crit = 0                             # Number of cars involved in HPRC violation.
    j = 1
    for i in 1:inst.nb_HPRC
        j = 1
        while j <= s.n
            if s.M2[i,j] > inst.RC_p[i]
                k = 0
                while k < inst.RC_p[i] && (j+k) <= s.n
                    if inst.RC_flag[j + k, i] == true && criticars[j + k] == 0
                        criticars[j + k] = 1
                        nb_crit = nb_crit + 1
                    end
                    k = k + 1
                end
                j = j + k   # Cars between indexes j and j+k already seen in second while so we can skip them
            end
            j = j + 1
        end
    end

    return criticars, nb_crit
end

function intensification(s::Solution, inst::Instance)
    #TODO
    return s
end

function restart(s::Solution, inst::Instance)
    #TODO
    return s
end


#----------------------#
#     COMPARATORS      #
#----------------------#

#Better Or Equal
function isBeq(s1::Solution, s2::Solution, inst::Instance)
    return costHPRC(s1, inst) >= costHPRC(s2, inst)
end

#Equal
function isEqual(s1::Solution, s2::Solution, inst::Instance)
    return costHPRC(s1, inst) == costHPRC(s2, inst)
end

#Strictly Better
function isBetter(s1::Solution, s2::Solution, inst::Instance)
    return costHPRC(s1, inst) > costHPRC(s2, inst)
end






function ILS_HPRC(sol::Solution, inst::Instance)
    i = 0                               # Number of itération since the last improvement
    s = deepcopy(sol)
    S = s
    cond = false #TODO
    while cond
        neighbor = perturbation(s, int)
        crit = criticalCars(s, inst)
        if crit[2] > (s.n * 0.6)
            neighbor = localSearch(s, inst)
        else
            neighbor = fastLocalSearch(s, inst, crit[1])
        end
        if isBeq(nieghbor,s, inst)         # There is an improvement
            s = neighbor
            i = 0                       # So the number of iteration since the last improvement return to 0
        end
        if i == alpha
            s = intensification(s, inst)
        end
        if i == beta
            if isEqual(neighbor,s, inst)
                s = restart(s, inst)
            else
                s = S
            end
        end
        if isBetter(s,S, inst)
            S = s
        end
        i = i + 1
    end
    return S
end
