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
##                Algorithme ILS                     ##
##===================================================##




function ILS(s)
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



function perturbation(s)
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
