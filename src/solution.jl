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
    n:: Int
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
        zeros(Int,nC),#collect(1:nC),
        zeros(Int,nO,nC),
        zeros(Int,nO,nC),
        zeros(Int,nO,nC)
    )
end


# Build an initial
function init_solution(nom_fichier::String, type_fichier::String)
    # Read in data files
    instance = parser(nom_fichier, type_fichier)

    n = length(instance.color_code)
    m = instance.nb_HPRC + instance.nb_LPRC # number of ratio
    solution = Solution(n,m)

    for i in 1:instance.nb_late_prec_day
        solution.sequence[i] = i
    end
    return solution
end

# Build an initial
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
    update_matrices!(solution::Solution, nb::Int, instance::Instance)

Update `solution.M1`, `solution.M2` and `solution.M3` for known cars at positions 1 to nb.
"""
function update_matrices!(solution::Solution, nb::Int, instance::Instance)
    nb_RC = instance.nb_HPRC+instance.nb_LPRC

    # Last column has just one car
    for option in 1:nb_RC
        car = solution.sequence[nb]
        if instance.RC_flag[car,option]
            solution.M1[option,nb] = 1
        end
    end

    # Dynamic (right to left)
    for counter in 0:(nb-1)
        index = nb-counter
        car = solution.sequence[index]
        for option in 1:nb_RC
            # Has option -> next sequence + 1
            if instance.RC_flag[car,option]
                solution.M1[option,index] = solution.M1[option,index+1] + 1
            else
                solution.M1[option,index] = solution.M1[option,index+1]
            end

            # Is there one car not reach anymore ?
            index_first_out = index + instance.RC_q[option]
            if index_first_out <= nb
                car_first_out = solution.sequence[index_first_out]
                # It had option -> sequence - 1
                if instance.RC_flag[car_first_out,option]
                    solution.M1[option,index] = solution.M1[option,index] - 1
                end
            end
        end
    end

    # Update M2 and M3 (left to right)
    for option in 1:nb_RC
        solution.M2[option, 1] = (solution.M1[option, 1] >  instance.RC_p[option] ? 1 : 0)
        solution.M3[option, 1] = (solution.M1[option, 1] >= instance.RC_p[option] ? 1 : 0)
        for index in 2:nb
            solution.M2[option, index] = solution.M2[option, index-1] + (solution.M1[option, index] >  instance.RC_p[option] ? 1 : 0)
            solution.M3[option, index] = solution.M3[option, index-1] + (solution.M1[option, index] >= instance.RC_p[option] ? 1 : 0)
        end
    end
end

"""
    update_matrices_new_car!(solution::Solution, position::Int, instance::Instance)

Update `solution.M1`, `solution.M2` and `solution.M3` for a new car add at a given position.
DOES NOT update columns for sequences excluding the position. Assert made : the function is called
when we add a car in an tail-less sequence.
"""
function update_matrices_new_car!(solution::Solution, position::Int, instance::Instance)
    nb_RC = instance.nb_HPRC+instance.nb_LPRC
    car = solution.sequence[position]

    for option in 1:nb_RC
        for index in (position - instance.RC_q[option] + 1):position
            if index > 0
                # new car has option -> update M1
                if instance.RC_flag[car,option]
                    solution.M1[option,index] = solution.M1[option,index] + 1
                end

                # Columns of M2 and M3 can be update
                if index == 1
                    solution.M2[option,index] = 0 + (solution.M1[option,index] >  instance.RC_p[option] ? 1 : 0)
                    solution.M3[option,index] = 0 + (solution.M1[option,index] >= instance.RC_p[option] ? 1 : 0)
                else
                    solution.M2[option,index] = solution.M2[option,index-1] + (solution.M1[option,index] >  instance.RC_p[option] ? 1 : 0)
                    solution.M3[option,index] = solution.M3[option,index-1] + (solution.M1[option,index] >= instance.RC_p[option] ? 1 : 0)
                end
            end
        end
    end
end
