#=
# VNS for the RENAULT Roadef 2005 challenge
# inspired by work of
# Celso C. Ribeiro, Daniel Aloise, Thiago F. Noronha, Caroline Rocha, Sebastián Urrutia
#
# @Author Boualem Lamraoui, Benoît Le Badezet, Benoit Loger, Jonathan Fontaine, Killian Fretaud, Rémi Garcia
# =#



# Complete strategy can be summerize as follow:
#
#   (1) Use a constructive heuristic to find an initial solution.
#   (2) Use an improvement heuristic to optimize the first objective.
#   (3) Use an improvement heuristic to optimize the second objective.
#   (4) Use a repair heuristic to make the current solution feasible.
#   (5) Use an improvement heuristic to optimize the third objective.
#

include("parser.jl")
include("solution.jl")


##===================================================##
##           Data stucture and Parser                ##
##===================================================##

nom_fichier = "022_3_4_EP_RAF_ENP"
type_fichier = "A"

solution = init_solution(nom_fichier, type_fichier)

##===================================================##
##                Greedy algorithms                  ##
##===================================================##

# TODO: need to know data representation for this one

#= Idea:
#
#   next candidate is car c such that
#       c induces the smallest number of new violations
#   tie --> tie breaking criterion to maximize
#       sum (on j) of (oj = 0) XOR (more oj out than in pi)
#   tie --> options with high utilization rate first
#
# =#


##===================================================##
##                 Useful variables                  ##
##===================================================##

# Number of neighborhoods for VNS
k_max = 1

# Must be read in data files
C = 10 # Number of cars
W = 3 # Number of cars for the current day
b0 = C - W # First index for the current day





##===================================================##
##                Useful algorithms                  ##
##===================================================##


# For a fixed neighborhood
function perturbation(s)
    #TODO
    return s
end

# For a given neighborhood
function perturbation(s, Nk)
    #TODO
    return s
end

function move(s, i, j)
    #TODO
    return s
end

function acceptanceCriterion(s1, s2)
    #TODO
    return false
end

function isBetter(s1, s2)
    #TODO
    return false
end

function cost(s)
    #TODO
    return 0
end

function localSearch(s)
    while true
        phi = cost(s)
        for i in b0:length(s)
            best_delta = 0
            L = []
            for j in b0:length(s)
                delta = cost(move(s, i, j)) - cost(s)
                if delta < best_delta
                    L = [j]
                    best_delta = delta
                elseif delta == best_delta
                    push!(L, j)
                end
            end
            if L != []
                #TODO: choose k in L randomly
                s = move(s, i, j)
            end
        end
        if phi == cost(s)
            break
        end
    end

    return s
end


function intensification(s)
    #TODO
    return s
end

function diversification(s)
    #TODO
    return s
end


##===================================================##
##                 Algorithm ILS                     ##
##===================================================##




function generic_ILS(s)
    S = copy(s)
    cond = false #TODO
    while cond
        neighbor = perturbation(s)
        neighbor = localSearch(neighbor)
        if acceptanceCriterion(s, neighbor)
            s = neighbor
        end
        if isBetter(s,S)
            S = s
        end
    end
    return S
end


function generic_extended_ILS(s)
    S = copy(s)
    cond = false #TODO
    while cond
        neighbor = perturbation(s)
        neighbor = localSearch(neighbor)
        if acceptanceCriterion(s, neighbor)
            s = neighbor
        end
        intensification_cond = false
        if intensification_cond
            s = intensification(s)
        end
        diversification_cond = false
        if diversification_cond
            s = diversification(s)
        end
        if isBetter(s,S)
            S = s
        end
    end
    return S
end



##===================================================##
##                 Algorithm VNS                     ##
##===================================================##


function generic_VNS(s)
    S = copy(s)
    cond = false #TODO
    while cond
        k = 1
        while k < k_max
            neighbor = perturbation(s, Nk)
            neighbor = localSearch(neighbor)
            if acceptanceCriterion(s, neighbor)
                s = neighbor
                s = 1
            else
                k = k + 1
            end
            if isBetter(s,S)
                S = s
            end
        end
    end
    return S
end


function generic_extended_VNS(s)
    S = copy(s)
    cond = false #TODO
    while cond
        k = 1
        while k < k_max
            neighbor = perturbation(s, Nk)
            neighbor = localSearch(neighbor)
            if acceptanceCriterion(s, neighbor)
                s = neighbor
                s = 1
            else
                k = k + 1
            end
            s = intensification(s)
            if isBetter(s,S)
                S = s
            end
        end
    end
    return S
end

##===================================================##
##                 Algorithm VNS_LPRC                ##
##===================================================##


function perturbation_VNS_LPRC(sol::Solution, p::Int, k::Int, instance::Instances)
    # TODO
    return Solution(1, 1)
end

function localSearch_VNS_LPRC(neighbor::Solution, instance::Instances)
    # TODO
    return Solution(1, 1)
end

function intensification_VNS_LPRC(sol::Solution, instance::Instances)
    # TODO
    return Solution(1, 1)
end

function cost_VNS_LPRC(sol::Solution, instance::Instances)
    nb_HPRC_violated = sum(sol.M2[i, end] for i in 1:instance.nb_HPRC)
    nb_LPRC_violated = sum(sol.M2[instance.nb_HPRC + i, end] for i in 1:instance.nb_LPRC)
    # Each HPRC non violated is better than all LPRC non violated because we do a lexical order.
    lex_factor = instance.nb_LPRC * 2 + 1 # + 1 because some times there is no LPRC.
    return lex_factor*nb_HPRC_violated + nb_LPRC_violated
end

function VNS_LPRC(sol::Solution, instance::Instances)
    # solutions
    s_opt = deepcopy(sol)
    s = deepcopy(sol)
    # variable of the algorithm
    k_min = [3, 5]
    k_max = [8, 12]
    p = 1
    k = k_min[p+1]
    nb_intens_not_better = 0
    while nb_intens_not_better < 150
        while k < k_max[p+1]
            neighbor = perturbation_VNS_LPRC(s, p, k, instance)
            neighbor = localSearch_VNS_LPRC(neighbor, instance)
            if cost_VNS_LPRC(neighbor, instance) < cost_VNS_LPRC(s, instance)
                s = neighbor
                k = k_min[p+1]
            else
                k = k + 1
            end
            s = intensification_VNS_LPRC(s, instance)
            nb_intens_not_better += 1
            if cost_VNS_LPRC(s, instance) < cost_VNS_LPRC(S, instance)
                s_opt = s
                nb_intens_not_better = 0
            end
        end
        p = 1 - p
        k = k_min[p+1]
    end
    return s_opt
end
