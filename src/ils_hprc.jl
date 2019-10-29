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

function perturbation(s)
    #TODO

end


function move(s, i j)
    #TODO

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

end

function restart(s)
    #TODO

end


#----------------------#
#     COMPARATORS      #
#----------------------#

function isBeq(s1, s2)
    #TODO

end

function isEqual(s1, s2)
    #TODO

end

function isBetter(s1, s2)
    #TODO

end






function ILS_HPRC(s)
    i = 0                               # Number of itération since the last improvement
    S = s
    cond = false #TODO
    while cond
        neighbor = perturbation(s)
        neighbor = localSearch(s)
        if isBeq(nieghbor,s)         # There is an improvement
            s = neighbor
            i = 0                       # So the number of iteration since the last improvement return to 0
        end
        if i = alpha
            s = intensification(s)
        end
        if i = beta
            if isEqual(neighbor,s)
                s = restart(s)
            else
                s = S
            end
        end
        if isBetter(s,S)
            S = s
        end

        i = i + 1
    end
    return S
end
