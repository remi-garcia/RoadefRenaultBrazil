#=
# VNS for the RENAULT Roadef 2005 challenge
# inspired by work of
# Celso C. Ribeiro, Daniel Aloise, Thiago F. Noronha, Caroline Rocha, Sebastián Urrutia
#
# @Author Boualem Lamraoui, Benoît Le Badezet, Benoit Loger, Jonathan Fontaine, Killian Fretaud, Rémi Garcia
=#



# Complete strategy can be summerize as follow :
#
#   (1) Use a constructive heuristic to find an initial solution.
#   (2) Use an improvement heuristic to optimize the first objective.
#   (3) Use an improvement heuristic to optimize the second objective.
#   (4) Use a repair heuristic to make the current solution feasible.
#   (5) Use an improvement heuristic to optimize the third objective.
#


##===================================================##
##               Usefull algorithms                  ##
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



function localSearch(s)
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
s = intensification(s)        end
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


# Number of neighborhoods
k_max = 1

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
