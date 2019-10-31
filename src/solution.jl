mutable struct Solution
    n::Int
        # Size
    sequence::Array{Int, 1}
        # vector of cars (sequence pi or s in the following algorithms)
    M1::Array{Int, 2}
        # M1_ij is the number of cars with oj in the subsequence of
        # q(oj) cars starting at position i of sequence pi
    M2::Array{Int, 2}
        # M2_ij is the number of subsequences of q(oj) cars starting
        # at positions 1 up to i in which the number of cars that
        # require oj is greater than p(oj)
    M3::Array{Int, 2}
        # M3_ij is the number of subsequences in which the number of
        # cars that require oj is greater than or equal to p(oj)

    Solution(nC::Int,nO::Int) = new(
        nC,
        zeros(Int,nC),
        zeros(Int,nO,nC),
        zeros(Int,nO,nC),
        zeros(Int,nO,nC)
    )
end

"""
TODO
"""
function init_solution(nom_fichier::String, type_fichier::String)
    # Read in data files
    instance = parser(nom_fichier, type_fichier)

    return init_solution(instance)
end

"""
TODO
"""
function init_solution(instance::Instance)
    n = length(instance.color_code)
    m = instance.nb_HPRC + instance.nb_LPRC # number of ratio
    solution = Solution(n,m)

    for i in 1:instance.nb_late_prec_day
        solution.sequence[i] = i
    end

    return solution
end

"""
    compute_Ms!(solution::Solution)

Computes `solution.M1`, `solution.M2` and `solution.M3` given
`solution.sequence` and an instance.
"""
function compute_Ms!(solution::Solution, instance::Instance)
    n = length(solution.sequence)
    m = instance.nb_HPRC + instance.nb_LPRC # number of ratio
    solution.M1 = zeros(Int, m, n)
    solution.M2 = zeros(Int, m, n)
    solution.M3 = zeros(Int, m, n)
    # Update M1, M2 and M3 for the first car
    for j in 1:m
        for i in 1:instance.RC_q[j]
            if instance.flag[solution.sequence[i],j]
                solution.M1[j, 1] = 1
            end
        end
        # First column of M2 and M3 can be update
        solution.M2[j, 1] = (solution.M1[j, 1] >  instance.RC_p[j] ? 1 : 0)
        solution.M3[j, 1] = (solution.M1[j, 1] >= instance.RC_p[j] ? 1 : 0)

        # for each shift of sequence
        for i in 2:n
            current_i = solution.sequence[i]
            precedent_i = solution.sequence[i-1]
            solution.M1[j, current_i] = solution.M1[j, precedent_i]
            # previous case had flag -> not in anymore

            if instance.flag[precedent_i,j]
                solution.M1[j, current_i] = solution.M1[j, current_i] - 1
            end
            # new case has flag -> in now
            if (i + q[j] - 1) <= n
                other_i = solution.sequence[(i + q[j]) - 1]
                if instance.flag[other_i, j]
                    solution.M1[J, current_i] = solution.M1[J, current_i] + 1
                end
            end
            # First column of M2 and M3 can be update
            solution.M2[J, current_i] = solution.M2[J, precedent_i] + (solution.M1[J, current_i] >  instance.RC_p[j] ? 1 : 0)
            solution.M3[J, current_i] = solution.M3[J, precedent_i] + (solution.M1[J, current_i] >= instance.RC_p[j] ? 1 : 0)
        end
    end

    return solution
end
