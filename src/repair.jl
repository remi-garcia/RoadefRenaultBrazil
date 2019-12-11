#-------------------------------------------------------------------------------
# File: repair.jl
# Description: This files contains all function for the "repair" phase.
# Date: November 03, 2019
# Author: Jonathan Fontaine, Killian Fretaud, Rémi Garcia,
#         Boualem Lamraoui, Benoît Le Badezet, Benoit Loger
#-------------------------------------------------------------------------------

"""
    find_first_violation(solution::Solution, instance::Instance)

Return the index of the first car violating the paint_batch_limit constraint in the sequence,
return -1 if such a car does not exist
"""
function find_first_violation(solution::Solution, instance::Instance)
    first_violation = -1
    position = instance.nb_late_prec_day+1
    while position < solution.length
        if solution.colors[position].width > instance.nb_paint_limitation
            first_violation = position + instance.nb_paint_limitation
            break
        end
        position += solution.colors[position].width
    end
    return first_violation
end

"""
    first_strategy_repair!(solution::Solution, instance::Instance)

First strategy
"""
function first_strategy_repair!(solution::Solution, instance::Instance)
    # First strategy
    b0 = instance.nb_late_prec_day+1

    position = b0
    counter = 1
    current_color = instance.color_code[solution.sequence[position]]
    position += 1
    first_violation = 0
    while position <= instance.nb_cars
        if instance.color_code[solution.sequence[position]] == current_color
            counter += 1
        else
            counter = 1
            current_color = instance.color_code[solution.sequence[position]]
        end
        if counter > instance.nb_paint_limitation
            if position >= b0
                if first_violation == 0
                    first_violation = position
                end
                car_RC_value = instance.RC_keys[solution.sequence[position]]
                car_pos = 1
                len = length(instance.RC_cars[car_RC_value])
                while (car_pos <= len) && (instance.color_code[instance.RC_cars[car_RC_value][car_pos]] == current_color)
                    car_pos += 1
                end
                if car_pos <= len
                    move_exchange!(solution, position, car_pos, instance)
                    counter = first_violation - position
                    if first_violation >= position
                        position = first_violation - 1
                    else
                        position -= 1
                    end
                    first_violation = 0
                elseif first_violation >= position
                    position -= 2
                    if counter == 2*instance.nb_paint_limitation
                        # This strategy can't repair
                        position = first_violation
                    end
                end
            else
                if first_violation != 0
                    position = first_violation
                else
                    # pcc are not possible in nb_late_prec_day so we keep the counter
                end
            end
        end
        position += 1
    end

    position = 1
    counter = 1
    current_color = instance.color_code[solution.sequence[position]]
    position += 1
    first_violation = 0
    while position <= instance.nb_cars
        if instance.color_code[solution.sequence[position]] == current_color
            counter += 1
        else
            counter = 1
            current_color = instance.color_code[solution.sequence[position]]
        end
        if counter > instance.nb_paint_limitation
            if position >= b0
                if first_violation == 0
                    first_violation = position
                end
                car_HPRC_value = instance.HPRC_keys[solution.sequence[position]]
                car_pos = 1
                len = length(instance.HPRC_cars[car_HPRC_value])
                while (car_pos <= len) && (instance.color_code[instance.HPRC_cars[car_HPRC_value][car_pos]] == current_color)
                    car_pos += 1
                end
                if car_pos <= len
                    move_exchange!(solution, position, car_pos, instance)
                    counter = first_violation - position
                    if first_violation >= position
                        position = first_violation - 1
                    else
                        position -= 1
                    end
                    first_violation = 0
                elseif first_violation >= position
                    position -= 2
                    if counter == 2*instance.nb_paint_limitation
                        # This strategy can't repair
                        position = first_violation
                    end
                end
            else
                if first_violation != 0
                    position = first_violation
                else
                    # pcc are not possible in nb_late_prec_day so we keep the counter
                end
            end
        end
        position += 1
    end
end

"""
    second_repair!(solution::Solution, instance::Instance)

Second strategy
"""
function second_strategy_repair!(solution::Solution, instance::Instance)
    # Second strategy
    first_violation = find_first_violation(solution, instance)
    b0 = instance.nb_late_prec_day+1
    while first_violation != -1
        # Compute the best_insertion index
        solution_value = weighted_sum(solution, instance)
        cost_insertion = zeros(instance.nb_cars)
        for i in b0:instance.nb_cars
            if i <= instance.nb_late_prec_day || i == first_violation # avoiding insterting in sequence from the precedent day and at the same position
                cost_insertion[i] = Inf
            else
                #checking for validity of insertion :  if it does not add an other violation of Paint batch constraint
                batch_size = 1
                batch_color = instance.color_code[solution.sequence[first_violation]]
                if instance.color_code[solution.sequence[i]] == batch_color # if inserting create a batch of length greater than one
                    batch_size += 1
                    j = 1
                    same_batch_sup = true
                    same_batch_inf = true
                    while same_batch_inf || same_batch_sup
                        if i-j > 0 && instance.color_code[solution.sequence[i-j]] == batch_color && same_batch_inf
                            batch_size += 1
                        else
                            same_batch_inf = false
                        end

                        if i+j <= instance.nb_cars && instance.color_code[solution.sequence[i+j]] == batch_color && same_batch_sup
                            batch_size += 1
                        else
                            same_batch_sup = false
                        end
                        j += 1
                    end
                end
                if batch_size > instance.nb_paint_limitation
                    cost_insertion[i] = Inf
                else
                    solution_copy = deepcopy(solution)
                    move_insertion!(solution, first_violation, i, instance)
                    cost_insertion[i] = weighted_sum(solution_copy, instance) - solution_value
                end
            end
        end
        best_insertion = argmin(cost_insertion)[1]
        move_insertion!(solution, first_violation, best_insertion, instance)

        first_violation = find_first_violation(solution, instance)
    end
end


"""
    repair!(solution::Solution, instance::Instance)

Apply 2 repair strategies on `solution`.
"""
function repair!(solution::Solution, instance::Instance)
    if solution.colors === nothing
        initialize_batches!(solution, instance)
    end

    first_strategy_repair!(solution, instance)
    second_strategy_repair!(solution, instance)

    @assert find_first_violation(solution, instance) == -1
    return solution
end
