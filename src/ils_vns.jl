#=
# VNS for the RENAULT Roadef 2005 challenge
# inspired by work of
# Celso C. Ribeiro, Daniel Aloise, Thiago F. Noronha, Caroline Rocha, Sebastián Urrutia
#
# @Author Boualem Lamraoui, Benoît Le Badezet, Benoit Loger, Jonathan Fontaine, Killian Fretaud, Rémi Garcia
# =#



# Complete strategy can be summerize as follow :
#
#   (1) Use a constructive heuristic to find an initial solution.
#   (2) Use an improvement heuristic to optimize the first objective.
#   (3) Use an improvement heuristic to optimize the second objective.
#   (4) Use a repair heuristic to make the current solution feasible.
#   (5) Use an improvement heuristic to optimize the third objective.
#



##===================================================##
##                 Data stuctures                    ##
##===================================================##

# vector of cars (sequence pi or s in the following algorithms)
s = [1 2 3 4 5 6 7 8 9 10] # size n
# Three matrix m*n (rows = options, columns = cars)
M1 = []
    # M1_ij is the number of cars with oj in the subsequence of
    # q(oj) cars starting at position i of sequence pi
M2 = []
    # M2_ij is the number of subsequences of q(oj) cars starting
    # at positions 1 up to i in which the number of cars that
    # require oj is greater than p(oj)
M3 = []
    # M3_ij is the number of subsequences in which the number of
    # cars that require oj is greater than or equal to p(oj)




##===================================================##
##                Greedy algorithms                  ##
##===================================================##

# TODO : need to know data representation for this one

#= Idea :
#
#   next candidate is car v such that
#       v induces the smallest number of new violations
#   tie --> tie breaking criterion to maximize
#       sum (on j) of (oj = 0) XOR (more oj out than in pi)
#   tie --> options with high utilization rate first
#
# =#


##===================================================##
##                Usefull variables                  ##
##===================================================##

# Number of neighborhoods for VNS
k_max = 1

# Must be read in data files
V = 10 # Number of cars
W = 3 # Number of cars for the current day
b0 = V - W # First index for the current day





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
        for i in b0:size(s) #TODO : is it size(.) ?
            best_delta = 0
            L = []
            for j in b0:size(s) #TODO : is it size(.) ?
                delta = cost(move(s, i, j)) - cost(s)
                if delta < best_delta
                    L = [j]
                    best_delta = delta
                elseif delta == best_delta
                    push!(L, j)
                end
            end
            if L != []
                #TODO : choose k in L randomly
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
