#=
This file contains all function used to parse the data and return the data to an
appropriate format to be compute.

Link of the data : http://www.roadef.org/challenge/2005/fr/sujet.php
The data should be in ../data/Instances_Type/name_instance/
There is 3 types of instances labeled A, B and X, so folders
should be named Instances_A/, Instances_B/, and Instances_X/.
=#

# Constant of the problem
const OPTIMISATION_FILE_NAME = "optimization_objectives.txt"
const PAINT_FILE_NAME = "paint_batch_limit.txt"
const RATIO_FILE_NAME = "ratios.txt"
const VEHICLES_FILE_NAME = "vehicles.txt"

Car_ID = Int
Option = Int

# An Instance structure that is used to format data as we want.
struct Instance
    # objectif function
    HPRC_rank::Int
    LPRC_rank::Int # If there is no LPRC, LPRC_rank = -1
    PCB_rank::Int
    # paint limitation
    nb_paint_limitation::Int
    # ratio constraint
    RC_p::Array{Int, 1}
    RC_q::Array{Int, 1}
    nb_HPRC::Int
    nb_LPRC::Int
    # sequence vehicle data
    RC_flag::Array{Bool, 2}
    RC_keys::Array{Int, 1}
    HPRC_keys::Array{Int, 1}
    LPRC_keys::Array{Int, 1}
    same_RC::Dict{Int, Array{Car_ID, 1}}
    same_HPRC::Dict{Int, Array{Car_ID, 1}}
    same_LPRC::Dict{Int, Array{Car_ID, 1}}
    color_code::Array{Int, 1}
    same_color::Dict{Int, Array{Car_ID, 1}}
    # Number of vehicles that weren't build the precedent day.
    nb_late_prec_day::Int # Usage 1:nb_late_prec_day give the list of index of those vehicles.
    nb_cars::Int
end

function nb_HPRC(instance::Instance)
    return instance.nb_HPRC
end
function nb_LPRC(instance::Instance)
    return instance.nb_LPRC
end
function nb_RC(instance::Instance)
    return instance.nb_HPRC+instance.nb_LPRC
end

function HPRC_value(car::Car_ID, instance::Instance)
    return instance.HPRC_keys[car]
end
function LPRC_value(car::Car_ID, instance::Instance)
    return instance.LPRC_keys[car]
end
function RC_value(car::Car_ID, instance::Instance)
    return instance.RC_keys[car]
end

function option_p(option::Option, instance::Instance)
    return instance.RC_p[option]
end
function option_q(option::Option, instance::Instance)
    return instance.RC_q[option]
end

function get_color(car::Car_ID, instance::Instance)
    return instance.color_code[car]
end

function get_b0(instance::Instance)
    return instance.nb_late_prec_day+1
end
function get_nb_cars(instance::Instance)
    return instance.nb_cars
end

function has_option(car::Car_ID, option::Option, instance::Instance)
    return instance.RC_flag[car, option]
end

function get_cars_with_same_RC(car::Car_ID, instance::Instance)
    return instance.same_RC[RC_value(car, instance)]
end
function get_cars_with_same_HPRC(car::Car_ID, instance::Instance)
    return instance.same_HPRC[HPRC_value(car, instance)]
end
function get_cars_with_same_LPRC(car::Car_ID, instance::Instance)
    return instance.same_LPRC[LPRC_value(car, instance)]
end
function get_cars_with_same_color(car::Car_ID, instance::Instance)
    return instance.same_color[instance.color_code[car]]
end

"""
    parser(instance_name::String, instance_type::String, path_folder::String=string(@__DIR__)*"/../data/Instances_")

Returns return the instance of type instance_type parsed form the files in path_folder.
"""
function parser(instance_name::String, instance_type::String, path_folder::String=string(@__DIR__)*"/../data/Instances_")
    path = path_folder * instance_type * "/" * instance_name * "/"

    #Lecture  OPTIMISATION_FILE_NAME
    HPRC_rank = 0
    LPRC_rank = -1
    PCB_rank = 0
    open(path * OPTIMISATION_FILE_NAME) do f
        lines = readlines(f)
        for i in 2:length(lines)
            if lines[i] != ""
                if lines[i][3] == 'h'
                    HPRC_rank = i-1
                elseif lines[i][3] == 'l'
                    LPRC_rank = i-1
                elseif lines[i][3] == 'p'
                    PCB_rank = i-1
                end
            end
        end
    end
    @assert HPRC_rank != 0
    @assert PCB_rank != 0

    #Lecture PAINT_FILE_NAME
    nb_paint_limitation = 0
    open(path * PAINT_FILE_NAME) do f
        lines = readlines(f)
        nb_paint_limitation = parse(Int, lines[2][1:(end-1)])
    end

    #Lecture RATIO_FILE_NAME
    nb_HPRC = 0
    nb_LPRC = 0
    RC_p = Array{Int,1}()
    RC_q = Array{Int,1}()
    open(path * RATIO_FILE_NAME) do f
        lines = readlines(f)
        for line in lines[2:end]
            if line != ""
                values = split(line, ";", limit=2)
                ratio = split(values[1], "/")
                push!(RC_p, parse(Int, ratio[1]))
                push!(RC_q, parse(Int, ratio[2]))
                if values[2][1] == '1'
                    nb_HPRC += 1
                elseif values[2][1] == '0'
                    nb_LPRC += 1
                end
            end
        end
    end

    # TODO:
    # string(Int(RC_flag[car, option])) * RC_value
    # become RC_value *string(Int(RC_flag[car, option]))
    # then:
    # two cars -> difference in RC value is less than 2^nb_LPRC
    # one array not needed but more time to compute difference later
    #Lecture VEHICLES_FILE_NAME
    day = 0
    indice = 0
    nb_RC = nb_HPRC + nb_LPRC
    color_code = Array{Int, 1}()
    RC_keys = Array{Int, 1}()
    HPRC_keys = Array{Int, 1}()
    LPRC_keys = Array{Int, 1}()
    RC_flag = Array{Bool, 2}(undef, 0, nb_RC)
    same_RC = Dict{Int, Array{Car_ID, 1}}()
    same_HPRC = Dict{Int, Array{Car_ID, 1}}()
    same_LPRC = Dict{Int, Array{Car_ID, 1}}()
    same_color = Dict{Int, Array{Car_ID, 1}}()
    nb_cars = 0
    nb_cars_total = 0
    nb_late_prec_day = 0
    open(path * VEHICLES_FILE_NAME) do f
        lines = readlines(f)
        if lines[end] == ""
            nb_cars_total = length(lines) - 2
        else
            nb_cars_total = length(lines) - 1
        end
        RC_flag = Array{Bool, 2}(undef, nb_cars_total, nb_RC)
        color_code = Array{Int, 1}(undef, nb_cars_total)
        RC_keys = Array{Int, 1}(undef, nb_cars_total)
        HPRC_keys = Array{Int, 1}(undef, nb_cars_total)
        LPRC_keys = Array{Int, 1}(undef, nb_cars_total)
        for line in lines[2:end]
            if line != ""
                values = split(line, ";", keepempty = false)
                nb_cars += 1
                car_RC_value = "0"
                for rc in 5:length(values)
                    RC_flag[nb_cars, rc - 4] = (values[rc] == "1")
                    car_RC_value *= values[rc]
                end
                RC_keys[nb_cars] = parse(Int, car_RC_value, base = 2)
                HPRC_keys[nb_cars] = parse(Int, SubString(car_RC_value, 1:(nb_HPRC+1)), base = 2)
                LPRC_keys[nb_cars] = parse(Int, "0"*SubString(car_RC_value, (nb_HPRC+2)), base = 2)
                color_code[nb_cars] = parse(Int, values[4])
                if nb_late_prec_day == 0
                    date = split(values[1], " ")
                    if date[3] != day
                        day = date[3]
                        nb_late_prec_day = nb_cars-1
                        same_RC[RC_keys[nb_cars]] = Array{Car_ID, 1}([nb_cars])
                        same_HPRC[HPRC_keys[nb_cars]] = Array{Car_ID, 1}([nb_cars])
                        same_LPRC[LPRC_keys[nb_cars]] = Array{Car_ID, 1}([nb_cars])
                        same_color[color_code[nb_cars]] = Array{Car_ID, 1}([nb_cars])
                    end
                else
                    if !haskey(same_RC, RC_keys[nb_cars])
                        same_RC[RC_keys[nb_cars]] = Array{Car_ID, 1}([nb_cars])
                        if !haskey(same_HPRC, HPRC_keys[nb_cars])
                            same_HPRC[HPRC_keys[nb_cars]] = Array{Car_ID, 1}([nb_cars])
                        else
                            push!(same_HPRC[HPRC_keys[nb_cars]], nb_cars)
                        end
                        if !haskey(same_LPRC, LPRC_keys[nb_cars])
                            same_LPRC[LPRC_keys[nb_cars]] = Array{Car_ID, 1}([nb_cars])
                        else
                            push!(same_LPRC[LPRC_keys[nb_cars]], nb_cars)
                        end
                    else
                        push!(same_RC[RC_keys[nb_cars]], nb_cars)
                        push!(same_HPRC[HPRC_keys[nb_cars]], nb_cars)
                        push!(same_LPRC[LPRC_keys[nb_cars]], nb_cars)
                    end
                    if !(color_code[nb_cars] in keys(same_color))
                        same_color[color_code[nb_cars]] = Array{Car_ID, 1}([nb_cars])
                    else
                        push!(same_color[color_code[nb_cars]], nb_cars)
                    end
                end
            end
        end
    end
    @assert nb_cars_total == nb_cars

    # RC_cars = Dict{Int, Array{Int, 1}}()
    # HPRC_cars = Dict{Int, Array{Int, 1}}()
    # for car in (nb_late_prec_day+1):nb_cars
    #     RC_key_binary = "0"
    #     HPRC_key_binary = "0"
    #     for option in 1:nb_HPRC
    #         RC_key_binary = string(Int(RC_flag[car, option])) * RC_key_binary
    #         HPRC_key_binary = string(Int(RC_flag[car, option])) * HPRC_key_binary
    #     end
    #     for option in (nb_HPRC+1):nb_LPRC
    #         RC_key_binary = string(Int(RC_flag[car, option])) * RC_key_binary
    #     end
    #     RC_key_bis = parse(Int, string(RC_key_binary), base = 2)
    #     HPRC_key_bis = parse(Int, string(HPRC_key_binary), base = 2)
    #
    #     if !haskey(RC_cars, RC_key_bis)
    #         RC_cars[RC_key_bis] = [car]
    #     else
    #         push!(RC_cars[RC_key_bis], car)
    #     end
    #     if !haskey(HPRC_cars, HPRC_key_bis)
    #         HPRC_cars[HPRC_key_bis] = [car]
    #     else
    #         push!(HPRC_cars[HPRC_key_bis], car)
    #     end
    # end

    return Instance(
            HPRC_rank, LPRC_rank, PCB_rank,                            # objectives file
            nb_paint_limitation,                                       # paint file
            RC_p, RC_q, nb_HPRC, nb_LPRC,                              # ratio file
            RC_flag, RC_keys, HPRC_keys, LPRC_keys,
            same_RC, same_HPRC, same_LPRC,
            #RC_cars, HPRC_cars, same_LPRC,
            color_code, same_color, nb_late_prec_day, nb_cars
        )
end
