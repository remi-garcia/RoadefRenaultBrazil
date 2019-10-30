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
    lex_factor = instance.nb_LPRC * length(instance.color_code) + 1 # + 1 because some times there is no LPRC.
    return lex_factor*nb_HPRC_violated + nb_LPRC_violated
end

function VNS_LPRC(sol::Solution, instance::Instances)
    # solutions
    s_opt = deepcopy(sol)
    s = deepcopy(sol)
    # variable of the algorithm
    # According to the paper, cf 6.1
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
