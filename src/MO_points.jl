#-------------------------------------------------------------------------------
# File: MO_points.jl
# Description: This file contains all functions relatives to Multi-Objectives points.
# Date: December 1, 2019
# Author: Jonathan Fontaine, Killian Fretaud, Rémi Garcia,
#         Boualem Lamraoui, Benoît Le Badezet, Benoit Loger
#-------------------------------------------------------------------------------

# Structure of a point
struct Point
    sequence::Array{Int, 1}
    cost::Tuple{Int, Int, Int}
end

"""
    Point(sequence::Array{Int, 1}, instance::Instance)

Return a `Point` with the `sequence` and compute the cost of it.
"""
Point(sequence::Array{Int, 1}, instance::Instance) =
    Point(sequence, Tuple{Int, Int, Int}(cost(sequence, instance, 3)))

"""
    Point(sequence::Array{Int, 1}, cost::Array{Int, 1})

Return a `Point` with the `sequence` and `cost` (changed in a Tuple).
"""
Point(sequence::Array{Int, 1}, cost::Array{Int, 1}) =
    Point(sequence, Tuple{Int, Int, Int}(cost))

"""
    dominate(left::Point, right::Point)

Test if `left` dominate `right` in a minimization MO context.
"""
function dominate(left::Point, right::Point)
    worse = false
    for i in 1:3
        worse |= left.cost[i] > right.cost[i]
    end
    return ! worse
end

"""
    dominated(point::Point, points_set::Set{Point})

Return if `point` is dominated by any point in `points_set`.
"""
function dominated(point::Point, points_set::Set{Point})
    # TODO Change the data structure later when it will be implemented
    dominated = false
    for p in points_set
        dominated |= dominate(p, point)
    end
    return dominated
end

"""
    improved_set(left_set::Set{Point}, right_set::Set{Point})

Return if `left_set` is a better solution that `right_set` in a minimization MO context.
"""
function improved_set(left_set::Set{Point}, right_set::Set{Point})
    # TODO Change the data structure later when it will be implemented
    better_set = false
    for point in left_set
        if !(point in right_set)
            better_set |= ! dominated(point, right_set)
        end
    end
    return better_set
end
