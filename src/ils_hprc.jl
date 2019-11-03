#=
# ILS_HRPC for the RENAULT Roadef 2005 challenge
# inspired by work of
# Celso C. Ribeiro, Daniel Aloise, Thiago F. Noronha, Caroline Rocha, Sebastián Urrutia
#
# @Author Boualem Lamraoui, Benoît Le Badezet, Benoit Loger, Jonathan Fontaine, Killian Fretaud, Rémi Garcia
# =#

#= CONSTANTATES TEMPORAIRES =#
const n_perturbation_HPRC = 5
const alpha = 25
const beta = 50
const stopping_criteria_ILSHPRC = 3

##=====================================##
##        USEFUL ALGORITHMS            ##
##=====================================##

function remove(s::Solution, inst::Instance, crit::Array{Int,1})
    i = inst.nb_late_prec_day+1
    removed = []
    while i <= s.n && length(removed) <= n_perturbation_HPRC
        #TODO plutot que de prendre les n premiers peut être faire un tirage aléatoire
        if crit[i] == 1
            push!(removed, s.sequence[i])
            deleteat!(s.sequence, i)
            s.n = s.n - 1
            update_matrices!(s, s.n, inst)
            deleteat!(crit, i)
        else
            i = i + 1
        end
    end
    return s, removed
end


function greedyadd(s::Solution, inst::Instance, car::Int)
    i = inst.nb_late_prec_day + 1
    tmp = deepcopy(s)
    splice!(tmp.sequence, i:i-1, car)
    tmp.n = tmp.n+1
    update_matrices!(tmp, tmp.n, inst)
    bestcost = costHPRC(tmp, inst)
    bestsol = deepcopy(tmp)
    deleteat!(tmp.sequence, i)
    for j in i:s.n
        splice!(tmp.sequence, j:j-1, car)
        update_matrices!(tmp, tmp.n, inst)
        ncost = costHPRC(tmp, inst)
        if ncost < bestcost
            bestcost = ncost
            bestsol = deepcopy(tmp)
        end
        deleteat!(tmp.sequence, j)
    end
    return bestsol
end


function perturbation(s::Solution, inst::Instance, crit::Array{Int,1})
    sol, removed = remove(s, inst, crit)
    for i in removed
        sol = greedyadd(sol, inst, i)
    end
    return sol
end

# Retourne le coût du premier objectif pour la solution s
function costHPRC(s::Solution, inst::Instance)
    c = sum(s.M2[i, s.n] for i in 1:inst.nb_HPRC)
    return c
end


function localSearch(s::Solution, inst::Instance, move!::Function, cost_move::Function)
    while true
        phi = costHPRC(s, inst)
        b0 = inst.nb_late_prec_day + 1      #First car of the current production day
        for i in b0:s.n
            best_delta = 0
            L = []
            for j in b0:s.n
                delta = cost_move(s, i, j, inst, 1) - costHPRC(s, inst)
                if delta < best_delta
                    L = [j]
                    best_delta = delta
                elseif delta == best_delta
                    push!(L, j)
                end
            end
            if L != []
                k = rand(L)
                move!(s, i, k, inst)
            end
        end
        if phi == costHPRC(s, inst)
            break
        end
    end

    return s
end

function fastLocalSearch(s::Solution, inst::Instance, move!::Function, cost_move::Function, crit::Array{Int, 1})
    while true
        phi = costHPRC(s, inst)
        b0 = inst.nb_late_prec_day + 1      #First car of the current production day
        for i in b0:s.n
            if crit[i] == 1
                best_delta = 0
                L = []
                for j in b0:s.n
                    delta = cost_move(s, i, j, inst, 1) - costHPRC(s, inst)
                    if delta < best_delta
                        L = [j]
                        best_delta = delta
                    elseif delta == best_delta
                        push!(L, j)
                    end
                end
                if L != []
                    k = rand(L)
                    move!(s, i, k, inst)
                end
            end
        end
        if phi == costHPRC(s, inst)
            break
        end
    end

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
    s = localSearch(s, inst, move_insertion!, cost_move_insertion)
    s = localSearch(s, inst, move_exchange!, cost_move_exchange)
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
    s_opt = deepcopy(sol)
    cond = 0 #TODO
    while cond < stopping_criteria_ILSHPRC
        crit = criticalCars(s, inst)
        neighbor = perturbation(s, inst, crit[1])
        crit = criticalCars(neighbor, inst)
        if crit[2] > (s.n * 0.6)
            neighbor = localSearch(neighbor, inst, move_exchange!, cost_move_exchange)
        else
            neighbor = fastLocalSearch(neighbor, inst, move_exchange!, cost_move_exchange, crit[1])
        end
        if costHPRC(s, inst) <= costHPRC(neighbor, inst)
            s = neighbor
        end
        if i == alpha
            s = intensification(s, inst)
        end
        if i == beta
            if costHPRC(neighbor, inst) < costHPRC(s, inst)
                #s = restart(s, inst)
                i = 0
                cond = cond + 1
            else
                s = s_opt
                cond = 0
            end
        end
        if costHPRC(s, inst) < costHPRC(s_opt, inst)            # There is an improvement
            s_opt = s
            i = 0                   # So the number of iteration since the last improvement shall return to 0
        end
        i = i + 1
        println(i)
    end
    return S
end
