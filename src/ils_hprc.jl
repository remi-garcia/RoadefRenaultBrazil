#-------------------------------------------------------------------------------
# File: ils_hprc.jl
# Description: ILS for the RENAULT Roadef 2005 challenge
#   inspired by work of
#   Celso C. Ribeiro, Daniel Aloise, Thiago F. Noronha,
#   Caroline Rocha, Sebastián Urrutia
#
# Date: November 03, 2019
# Author: Jonathan Fontaine, Killian Fretaud, Rémi Garcia,
#         Boualem Lamraoui, Benoît Le Badezet, Benoit Loger
#-------------------------------------------------------------------------------

##=====================================##
##        USEFUL ALGORITHMS            ##
##=====================================##

function remove(solution::Solution, instance::Instance, nbcar::Int, crit::Array{Int,1})
    i = instance.nb_late_prec_day+1
    removed = []
    while i <= solution.n && length(removed) <= nbcar
        #TODO plutot que de prendre les n premiers peut être faire un tirage aléatoire
        if crit[i] == 1
            push!(removed, solution.sequence[i])
            deleteat!(solution.sequence, i)
            solution.n = solution.n - 1
            update_matrices!(solution, solution.n, instance)
            deleteat!(crit, i)
        else
            i = i + 1
        end
    end
    return solution, removed
end


function greedyadd(solution::Solution, instance::Instance, car::Int)
    i = instance.nb_late_prec_day + 1
    tmp = deepcopy(solution)
    splice!(tmp.sequence, i:i-1, car)
    tmp.n = tmp.n+1
    update_matrices!(tmp, tmp.n, instance)
    bestcost = costHPRC(tmp, instance)
    bestsol = deepcopy(tmp)
    deleteat!(tmp.sequence, i)
    for j in i:solution.n
        splice!(tmp.sequence, j:j-1, car)
        update_matrices!(tmp, tmp.n, instance)
        ncost = costHPRC(tmp, instance)
        if ncost < bestcost
            bestcost = ncost
            bestsol = deepcopy(tmp)
        end
        deleteat!(tmp.sequence, j)
    end
    return bestsol
end


function perturbation(solution::Solution, instance::Instance, nbcar::Int, crit::Array{Int,1})
    sol, removed = remove(solution, instance, nbcar, crit)
    for i in removed
        sol = greedyadd(sol, instance, i)
    end
    return sol
end

# Retourne le coût du premier objectif pour la solution solution
function costHPRC(solution::Solution, instance::Instance)
    c = sum(solution.M2[i, solution.n] for i in 1:instance.nb_HPRC)
    return c
end


function localSearch(solution::Solution, instance::Instance, move!::Function, cost_move::Function)
    while true
        phi = costHPRC(solution, instance)
        b0 = instance.nb_late_prec_day + 1      #First car of the current production day
        for i in b0:solution.n
            best_delta = 0
            L = []
            for j in b0:solution.n
                delta = cost_move(solution, i, j, instance, 1) - costHPRC(solution, instance)
                if delta < best_delta
                    L = [j]
                    best_delta = delta
                elseif delta == best_delta
                    push!(L, j)
                end
            end
            if L != []
                k = rand(L)
                move!(solution, i, k, instance)
            end
        end
        if phi == costHPRC(solution, instance)
            break
        end
    end

    return solution
end

function fastLocalSearch(solution::Solution, instance::Instance, move!::Function, cost_move::Function, crit::Array{Int, 1})
    while true
        phi = costHPRC(solution, instance)
        b0 = instance.nb_late_prec_day + 1      #First car of the current production day
        for i in b0:solution.n
            if crit[i] == 1
                best_delta = 0
                L = []
                for j in b0:solution.n
                    delta = cost_move(solution, i, j, instance, 1) - costHPRC(solution, instance)
                    if delta < best_delta
                        L = [j]
                        best_delta = delta
                    elseif delta == best_delta
                        push!(L, j)
                    end
                end
                if L != []
                    k = rand(L)
                    move!(solution, i, k, instance)
                end
            end
        end
        if phi == costHPRC(solution, instance)
            break
        end
    end

    return solution
end

#Inidquate which cars are invloved in violation of HPRC and the number
function criticalCars(solution::Solution, instance::Instance)
    criticars = zeros(Int, solution.n)             # criticars[i] = 1 if car i violate HPRC otherwhise criticars[i] = 0
    nb_crit = 0                             # Number of cars involved in HPRC violation.
    j = 1
    for i in 1:instance.nb_HPRC
        j = 1
        while j <= solution.n
            if solution.M2[i,j] > instance.RC_p[i]
                k = 0
                while k < instance.RC_p[i] && (j+k) <= solution.n
                    if instance.RC_flag[j + k, i] == true && criticars[j + k] == 0
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

function intensification(solution::Solution, instance::Instance)
    solution = localSearch(solution, instance, move_insertion!, cost_move_insertion)
    solution = localSearch(solution, instance, move_exchange!, cost_move_exchange)
    return solution
end

function restart(solution::Solution, instance::Instance)
    crit = criticalCars(solution, instance)[1]
    solution = perturbation(solution, instance, NBCAR_DIVERSIFICATION, crit)
    return solution
end


function ILS_HPRC(solution::Solution, instance::Instance)
    i = 0                               # Number of itération since the last improvement
    s = deepcopy(solution)
    s_opt = deepcopy(solution)
    lastopt = deepcopy(solution)
    cond = 0 #TODO
    while cond < STOPPING_CRITERIA_ILS_HPRC && costHPRC(s_opt, instance) != 0
        crit = criticalCars(s, instance)
        neighbor = perturbation(s, instance, NBCAR_PERTURBATION, crit[1])
        crit = criticalCars(neighbor, instance)
        if crit[2] > (s.n * 0.6)
            println("LS")
            neighbor = localSearch(neighbor, instance, move_exchange!, cost_move_exchange)
        else
            println("FLS")
            neighbor = fastLocalSearch(neighbor, instance, move_exchange!, cost_move_exchange, crit[1])
        end
        if costHPRC(s, instance) <= costHPRC(neighbor, instance)
            s = neighbor
        end
        if i == ALPHA_ILS
            s = intensification(s, instance)
        end
        if i == BETA_ILS
            cond = cond + 1
            if costHPRC(lastopt, instance) > costHPRC(s_opt, instance)
                lastopt = s_opt
                cond = 0
            end
            if costHPRC(s, instance) == costHPRC(s_opt, instance) && cond < STOPPING_CRITERIA_ILS_HPRC
                s = restart(s, instance)
                i = 0
            elseif cond < STOPPING_CRITERIA_ILS_HPRC
                s = s_opt
                i = 0
            else
                s = greedy(instance)
            end
        end
        if costHPRC(s, instance) < costHPRC(s_opt, instance)            # There is an improvement
            s_opt = s
            i = 0                   # So the number of iteration since the last improvement shall return to 0
        else
            i = i + 1
        end
        #println(i)
    end
    return s_opt
end
