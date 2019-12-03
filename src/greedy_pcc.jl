#-------------------------------------------------------------------------------
# File: greedy_pcc.jl
# Description: This file contains all function used to construct
#         a first valid solution according to the pcc criterion.
# Date: October 31, 2019
# Author: Jonathan Fontaine, Killian Fretaud, Rémi Garcia,
#         Boualem Lamraoui, Benoît Le Badezet, Benoit Loger
#-------------------------------------------------------------------------------

"""
    greedy_pcc(instance::Instance)

Build an initial solution that give the best output for the Paint objective
"""
function greedy_pcc(instance::Instance)
    solution = init_solution(instance)
    len = (instance.nb_cars) - (instance.nb_late_prec_day)
    b0 = instance.nb_late_prec_day+1
    V = collect((b0):(instance.nb_cars))

    all_color = Set(instance.color_code)
    cost_on_objective = 0
    for i in 2:b0-1
        if instance.color_code[solution.sequence[i]] != instance.color_code[solution.sequence[i-1]]
            cost_on_objective += 1
        end
    end

    # Build an array that contains all index of cars of the same color.
    V_color = Array{Array{Int, 1}, 1}()
    for color in all_color
        push!(V_color, filter(ind -> instance.color_code[ind] == color, V))
    end

    # Sort by the biggest to the lowest number of car in each color,
    # to avoid some limit case (not all).
    sort!(V_color, by=list_color -> length(list_color), rev=true)

    index_seq = b0
    ended = false
    color=1
    if instance.color_code[V_color[color][1]] == instance.color_code[b0-1]
        col = instance.color_code[b0-1]
        count = 1
        while instance.color_code[b0-1-count] == col
            count += 1
        end
        if count + length(V_color[color]) > instance.nb_paint_limitation
            color += 1
        end
    end
    while ! ended
        color_count = 1
        while color_count <= instance.nb_paint_limitation && ! isempty(V_color[color])
            car = next_insertion(solution, index_seq, V_color[color], instance)
            solution.sequence[index_seq] = car
            index_seq += 1
            color_count += 1
            setdiff!(V_color[color], car)
        end
        # find color not done
        next_colors = findall(list_col -> ! isempty(list_col) && list_col != V_color[color] , V_color)
        if ! isempty(next_colors)
            color = next_colors[1]
        else
            ended = true
        end
    end

    # In some limit case (where there is a lot of cars in the same color or the batch limit is too low)
    # Some car may not be inserted. They all have the same color.

    color_not_ended = findall(list_col -> ! isempty(list_col), V_color)
    if ! isempty(color_not_ended)
        color = color_not_ended[1]
        n_cars_left = length(V_color[color])
        nb_insert_batch = ceil(Int, n_cars_left / instance.nb_paint_limitation)
        for _ in 1:nb_insert_batch
            nb_insert = min(instance.nb_paint_limitation, length(V_color[color]))
            # Find a position such that car_left should be a different color
            # than car_right and both of them should be different to color
            index_car_left = b0
            index_car_right = index_car_left+1
            while !(instance.color_code[solution.sequence[index_car_left]]
                    != instance.color_code[solution.sequence[index_car_right]]
                    && instance.color_code[solution.sequence[index_car_left]] != color
                    && instance.color_code[solution.sequence[index_car_right]] != color )
                index_car_left += 1
                index_car_right = index_car_left +1
            end
            # Shift values
            for index_copy in index_seq:-1:index_car_right
                solution.sequence[index_copy + nb_insert-1] = solution.sequence[index_copy-1]
            end
            # Insert
            for i in 1:nb_insert
                car = next_insertion(solution, index_seq, V_color[color], instance)
                solution.sequence[index_car_right+i-1] = car
                setdiff!(V_color[color], car)
            end
            index_seq += nb_insert
        end
    end

    update_matrices!(solution, instance.nb_cars, instance)
    return solution
end

"""
    next_insertion(solution::Solution, index::Int, available_cars::Array{Int, 1}, instance::Instance)

Return the next insertion at position index.
"""
function next_insertion(solution::Solution, index::Int, available_cars::Array{Int, 1}, instance::Instance)
    # TODO find a better insertion
    return rand(available_cars)
end
