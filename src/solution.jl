#-------------------------------------------------------------------------------
# File: greedy.jl
# Description: This file contains all functions related to the solution.
# Date: October 31, 2019
# Author: Jonathan Fontaine, Killian Fretaud, Rémi Garcia,
#         Boualem Lamraoui, Benoît Le Badezet, Benoit Loger
#-------------------------------------------------------------------------------

"""
    Solution

Create a empty sequence with matrices of zeros.
"""
mutable struct Solution
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

    length::Int

    Solution(nC::Int,nO::Int) = new(
        zeros(Int,nC),#collect(1:nC),
        zeros(Int,nO,nC),
        zeros(Int,nO,nC),
        zeros(Int,nO,nC),
        0
    )
end

# Build an initial
"""

"""
function init_solution(instance::Instance)
    n = instance.nb_cars
    m = instance.nb_HPRC + instance.nb_LPRC # number of ratio
    solution = Solution(n, m)

    for i in 1:instance.nb_late_prec_day
        solution.sequence[i] = i
    end
    solution.length = instance.nb_late_prec_day
    return solution
end

init_solution(nom_fichier::String, type_fichier::String) =
    init_solution(parser(nom_fichier, type_fichier))

"""
    update_matrices!(solution::Solution, instance::Instance)

Updates `solution.M1`, `solution.M2` and `solution.M3` for known cars at positions 1 to `solution.length`.
"""
function update_matrices!(solution::Solution, instance::Instance)
    nb_RC = instance.nb_HPRC + instance.nb_LPRC
    nb = solution.length

    # Last column has just one car
    for option in 1:nb_RC
        car = solution.sequence[nb]
        if instance.RC_flag[car, option]
            solution.M1[option, nb] = 1
        else
            solution.M1[option, nb] = 0
        end
    end

    # Dynamic (right to left)
    for counter in 1:(nb-1)
        index = nb - counter
        car = solution.sequence[index]
        for option in 1:nb_RC
            # Has option -> next sequence + 1
            if instance.RC_flag[car, option]
                solution.M1[option, index] = solution.M1[option, index+1] + 1
            else
                solution.M1[option, index] = solution.M1[option, index+1]
            end

            # Is there one car not reach anymore ?
            index_first_out = index + instance.RC_q[option]
            if index_first_out <= nb
                car_first_out = solution.sequence[index_first_out]
                # It had option -> sequence - 1
                if instance.RC_flag[car_first_out, option]
                    solution.M1[option, index] = solution.M1[option, index] - 1
                end
            end
        end
    end

    # Update M2 and M3 (left to right)
    for option in 1:nb_RC
        for index in 1:nb
            if index > 1
                solution.M2[option, index] = solution.M2[option, index-1]
                solution.M3[option, index] = solution.M3[option, index-1]
            else
               solution.M2[option, index] = 0
               solution.M3[option, index] = 0
            end
            # M3 is >=
            if solution.M1[option, index] >= instance.RC_p[option]
                solution.M3[option, index] += 1
                # M2 is >
                if solution.M1[option, index] > instance.RC_p[option]
                    solution.M2[option, index] += 1
                end
            end
        end
    end
end

"""
    update_matrices_new_car!(solution::Solution, position::Int, instance::Instance)

Updates `solution.M1`, `solution.M2` and `solution.M3` for a new car add at a given position.
DOES NOT update columns for sequences excluding the position. Assert made: the function is called
when we add a car in a tail-less sequence.
"""
function update_matrices_new_car!(solution::Solution, position::Int, instance::Instance)
    nb_RC = instance.nb_HPRC + instance.nb_LPRC
    car = solution.sequence[position]

    for option in 1:nb_RC
        for index in (position - instance.RC_q[option] + 1):position
            if index > 0
                # TODO: flag not raise -> index loop skipped
                # new car has option -> update M1
                if instance.RC_flag[car, option]
                    solution.M1[option, index] = solution.M1[option, index] + 1
                end

                # Columns of M2 and M3 can be update
                if index == 1
                    solution.M2[option, index] = 0
                    solution.M3[option, index] = 0
                else
                    solution.M2[option, index] = solution.M2[option, index-1]
                    solution.M3[option, index] = solution.M3[option, index-1]
                end

                # M3 is >=
                if solution.M1[option, index] >= instance.RC_p[option]
                    solution.M3[option, index] += 1
                    # M2 is >
                    if solution.M1[option, index] > instance.RC_p[option]
                        solution.M2[option, index] += 1
                    end
                end
            end
        end
    end
end
