#TODO This file should be removed when vns.jl and ils.jl are done.

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
