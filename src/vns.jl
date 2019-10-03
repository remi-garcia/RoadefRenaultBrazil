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
