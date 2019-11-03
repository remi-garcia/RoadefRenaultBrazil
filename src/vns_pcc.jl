#-------------------------------------------------------------------------------
# File: vns_pcc.jl
# Description: This files contains all function that are used in VNS_PCC.
# Date: November 03, 2019
# Author: Jonathan Fontaine, Killian Fretaud, Rémi Garcia,
#         Boualem Lamraoui, Benoît Le Badezet, Benoit Loger
#-------------------------------------------------------------------------------

"""
    repair!(solution::Solution, instance::Instance)

Apply 2 repair strategies on `solution`.
"""
function repair!(solution::Solution, instance::Instance)
    #TODO
    return solution
end

"""

"""
function perturbation_VNS_PCC_exchange(solution_init::Solution, k::Int, instance::Instance)

    return solution_init
end

"""

"""
function perturbation_VNS_PCC_insertion(solution_init::Solution, k::Int, instance::Instance)

    return solution_init
end

"""

"""
function intensification_VNS_PCC!(solution::Solution, instance::Instance)

    return solution
end

"""

"""
function localsearch_VNS_PCC!(solution::Solution, instance::Instance)
    #TODO JFontaine needs to take a look
    b0 = instance.nb_late_prec_day+1
    improved = true
    while improved
        solution_cost = cost(solution, instance, 3)
        phi = WEIGHTS_OBJECTIVE_FUNCTION[2] * solution_cost[2] + WEIGHTS_OBJECTIVE_FUNCTION[3] * solution_cost[3]
        for i in b0:solution.n
            best_delta = 0
            list = Array{Int, 1}()
            for j in (i+1):solution.n # exchange (i, j) is the same as exchange (j, i)
                if same_HPRC(solution, i, j, instance)
                    delta = cost_move_exchange(solution, i, j, instance, 2)[2]
                    if delta < best_delta
                        list = [j]
                        best_delta = delta
                    elseif delta == best_delta
                        push!(list, j)
                    end
                end
            end
            if !isempty(list)
                k = rand(list)
                move_exchange!(solution, i, k, instance)
            end
        end
        solution_cost = cost(solution, instance, 3)
        if phi == WEIGHTS_OBJECTIVE_FUNCTION[2] * solution_cost[2] + WEIGHTS_OBJECTIVE_FUNCTION[3] * solution_cost[3]
            improved = false
        end
    end
    return solution
end

"""

"""
function VNS_PCC(solution::Solution, instance::Instance, start_time::UInt)
    repair!(solution, instance)
    perturbations = Array{Function, 1}([perturbation_VNS_PCC_insertion, perturbation_VNS_PCC_exchange])
    p = 1
    k = VNS_PCC_MINMAX[p+1][1]
    cost_solution = sum_cost(solution, instance)
    cost_HPRC_solution = cost(solution, instance, 1)[1]
    while TIME_LIMIT > (time_ns() - start_time) / 1.0e9
        while k <= VNS_PCC_MINMAX[p+1][2]
            solution_perturbation = perturbations[p](solution, k, instance)
            if cost_HPRC_solution < cost(solution_perturbation, instance, 1)[1]
                solution_perturbation = deepcopy(solution)
            end
            localsearch_VNS_PCC!(solution_perturbation, instance)
            cost_solution_perturbation = sum_cost(solution_perturbation, instance)
            if cost_solution_perturbation < cost_solution
                k = VNS_PCC_MINMAX[p+1][1]
            else
                k += 1
            end
            if cost_solution_perturbation <= cost_solution
                solution = deepcopy(solution_perturbation)
                cost_HPRC_solution = cost(solution, instance, 1)[1]
                cost_solution = sum_cost(solution, instance)
            end
        end
        intensification_VNS_PCC!(solution, instance)
        p = 1 - p
        VNS_PCC_MINMAX[p+1][1]
    end

    return solution
end
