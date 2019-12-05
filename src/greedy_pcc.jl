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

    update_matrices!(solution, instance)

    all_color = Set(instance.color_code)

    # Build an array that contains all index of cars of the same color.
    V_color = Array{Array{Int, 1}, 1}()
    for color in all_color
        push!(V_color, filter(ind -> instance.color_code[ind] == color, V))
    end

    # Sort by the biggest to the lowest number of car in each color,
    # to avoid some limit case (not all).
    sort!(V_color, by=list_color -> length(list_color), rev=true)
    color_to_index = zeros(Int, length(all_color))
    for color in all_color
        if !isempty(V_color[color])
            color_to_index[instance.color_code[V_color[color][1]]] = color
        end
    end

    # Sequence car by batch of paint.
    index_seq = b0
    ended = false
    index_color = 1
    while !ended
        size = min(instance.nb_paint_limitation , length(V_color[index_color]))
        cars = next_batch_insertion(solution, index_seq, V_color[index_color], size, instance)
        for car in cars
            solution.sequence[index_seq] = car
            index_seq += 1
        end
        setdiff!(V_color[index_color], cars)

        # find color not done
        next_colors = findall(list_col -> ! isempty(list_col) && list_col != V_color[index_color] , V_color)
        if ! isempty(next_colors)
            index_color = next_colors[1]
        else
            ended = true
        end
    end

    # In some limit case (where there is a lot of cars in the same color or the batch limit is too low)
    # Some car may not be inserted. They all have the same color.

    color_not_ended = findall(list_col -> ! isempty(list_col), V_color)
    if !isempty(color_not_ended)
        index_color = color_not_ended[1]
        color = instance.color_code[V_color[index_color][1]]
        n_cars_left = length(V_color[index_color])
        nb_insert_batch = ceil(Int, n_cars_left / instance.nb_paint_limitation)
        for _ in 1:nb_insert_batch
            nb_insert = min(instance.nb_paint_limitation, length(V_color[index_color]))
            # Find a position such that car_left should be a different color
            # than car_right and both of them should be different to color
            index_car_left = b0
            index_car_right = index_car_left+1
            stop = false
            while !stop && !(instance.color_code[solution.sequence[index_car_left]]
                    != instance.color_code[solution.sequence[index_car_right]]
                    && instance.color_code[solution.sequence[index_car_left]] != color
                    && instance.color_code[solution.sequence[index_car_right]] != color )
                index_car_left += 1
                index_car_right = index_car_left +1
                stop = solution.sequence[index_car_right] == 0 # no place to insert
            end
            if stop # insert between the same color
                index_car_left = b0
                index_car_right = index_car_left+1
                while !(instance.color_code[solution.sequence[index_car_left]] != color
                        && instance.color_code[solution.sequence[index_car_right]] != color )
                    index_car_left += 1
                    index_car_right = index_car_left +1
                end
            end
            # Shift values
            for index_copy in index_seq:-1:index_car_right
                solution.sequence[index_copy + nb_insert-1] = solution.sequence[index_copy-1]
            end
            # Insert
            for i in 1:nb_insert
                car = next_insertion(solution, index_car_right+i-1, V_color[index_color], instance)
                solution.sequence[index_car_right+i-1] = car
                setdiff!(V_color[index_color], car)
            end
            index_seq += nb_insert
        end
    end
    solution.length = instance.nb_cars
    update_matrices!(solution, instance)
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


"""
    next_batch_insertion(solution::Solution, index::Int, available_cars::Array{Int, 1}, instance::Instance)

Return the next batch to insert in solution according to the HPRC greedy criterion.
"""
function next_batch_insertion(solution::Solution, index::Int, available_cars::Array{Int, 1}, size::Int, instance::Instance)
    batch = Array{Int, 1}()
    for i in 1:size
        car = next_insertion(solution, index, setdiff(available_cars, batch), instance)
        push!(batch, car)
    end

    return batch
end
