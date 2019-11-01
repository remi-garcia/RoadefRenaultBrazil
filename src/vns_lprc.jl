#=
# VNS_LPRC for the RENAULT Roadef 2005 challenge
# inspired by work of
# Celso C. Ribeiro, Daniel Aloise, Thiago F. Noronha, Caroline Rocha, Sebastián Urrutia
#
# @Author Boualem Lamraoui, Benoît Le Badezet, Benoit Loger, Jonathan Fontaine, Killian Fretaud, Rémi Garcia
# =#

include("parser.jl")
include("solution.jl")
include("functions.jl")
include("constants.jl")

function perturbation_VNS_LPRC_exchange(solution::Solution, k::Int, instance::Instances)
    # TODO
    return Solution(1, 1)
end

function perturbation_VNS_LPRC_insertion(solution::Solution, k::Int, instance::Instances)
    # TODO
    return Solution(1, 1)
end

# Perturbation of VNS_LPRC
function perturbation_VNS_LPRC(solution::Solution, p::Int, k::Int, instance::Instances)
    if p == 0
        return perturbation_VNS_LPRC_exchange(solution, k, instance)
    else
        return perturbation_VNS_LPRC_insertion(solution, k, instance)
    end
end

# The Local Search is based on a car exchange move.
function localSearch_VNS_LPRC!(solution::Solution, instance::Instances)

    # TODO only move_exchange allowed
    p = 0
    # Select the move
    move! = [move_exchange!, move_insertion!][p+1]
    cost_move = [cost_move_exchange, cost_move_insertion][p+1]

    nb_vehicles = length(solution.sequence)
    b0 = instance.nb_late_prec_day+1

    improved = true
    while improved
        phi = cost(solution)
        for i in b0:nb_vehicles
            best_delta = 0
            list = Array{Int, 1}()
            for j in b0:nb_vehicles
                # TODO Accept to move with (i, j) only in specific case.
                delta = cost_move(solution, i, j, instance, 2)
                if delta < best_delta
                    list = [j]
                    best_delta = delta
                elseif delta == best_delta
                    push!(list, j)
                end
            end
            if list != []
                k = rand(list)
                move!(solution, i, k)
            end
        end
        if phi == cost(solution)
            improved = false
        end
    end
end

function intensification_VNS_LPRC(solution::Solution, instance::Instances)
    # TODO
    return Solution(1, 1)
end

# Return a tuple of solution, first element is the cost,and the second one is the number of HRPC violated.
function cost_VNS_LPRC(solution::Solution, instance::Instances)
    nb_HPRC_violated = sum(solution.M2[i, end] for i in 1:instance.nb_HPRC)
    nb_LPRC_violated = sum(solution.M2[instance.nb_HPRC + i, end] for i in 1:instance.nb_LPRC)
    cost = WEIGHTS_OBJECTIVE_FUNCTION[1] * nb_HPRC_violated + WEIGHTS_OBJECTIVE_FUNCTION[2] * nb_LPRC_violated
    return cost
end

# function that determine if left is better than right.
function is_better_VNS_LPRC(left::Solution, right::Solution, instance::Instances)
    left_cost = cost_VNS_LPRC(left, instance)
    right_cost = cost_VNS_LPRC(right, instance)

    nb_HPRC_violated_left = sum(left.M2[i, end] for i in 1:instance.nb_HPRC)
    nb_HPRC_violated_right = sum(right.M2[i, end] for i in 1:instance.nb_HPRC)

    cost_better = left_cost < right_cost
    HPRC_not_worse = nb_HPRC_violated_left <= nb_HPRC_violated_right

    return  cost_better && HPRC_not_worse
end

# VNS-LPRC algorithm describe in section 6.
function VNS_LPRC(solution::Solution, instance::Instances)
    # solutions
    s = deepcopy(solution)
    s_opt = s
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
            localSearch_VNS_LPRC!(neighbor, instance)
            if is_better_VNS_LPRC(neighbor, s, instance)
                s = neighbor
                k = k_min[p+1]
            else
                k = k + 1
            end
            s = intensification_VNS_LPRC(s, instance)
            nb_intens_not_better += 1

            if is_better_VNS_LPRC(s, s_opt, instance)
                s_opt = s
                nb_intens_not_better = 0
            end
        end
        p = 1 - p
        k = k_min[p+1]
    end
    return s_opt
end