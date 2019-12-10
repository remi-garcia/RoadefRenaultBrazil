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
    color_code::Array{Int, 1}
    # Number of vehicles that weren't build the precedet day.
    nb_late_prec_day::Int # Usage 1:nb_late_prec_day give the list of index of those vehicles.
    nb_cars::Int
    # description of cars
    RC_cars::Dict{Int, Array{Int, 1}}
    HPRC_cars::Dict{Int, Array{Int, 1}}
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

    #Lecture VEHICLES_FILE_NAME
    day = 0
    indice = 0
    nb_RC = nb_HPRC + nb_LPRC
    color_code = Array{Int, 1}()
    RC_flag = Array{Bool, 2}(undef, 0, nb_RC)
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
        color_code = zeros(Int, nb_cars_total)
        for line in lines[2:end]
            if line != ""
                values = split(line, ";", keepempty = false)
                if nb_late_prec_day == 0
                    date = split(values[1], " ")
                    if date[3] != day
                        day = date[3]
                        nb_late_prec_day = nb_cars
                    end
                end
                nb_cars += 1
                for rc in 5:length(values)
                    RC_flag[nb_cars, rc - 4] = (values[rc] == "1")
                end
                color_code[nb_cars] = parse(Int, values[4])
            end
        end
    end
    @assert nb_cars_total == nb_cars

    # TODO:
    # string(Int(RC_flag[car, option])) * RC_value
    # become RC_value *string(Int(RC_flag[car, option]))
    # then:
    # two cars -> difference in RC value is less than 2^nb_LPRC
    # one array not needed but more time to compute difference later
    RC_cars = Dict{Int, Array{Int, 1}}()
    HPRC_cars = Dict{Int, Array{Int, 1}}()
    for car in (nb_late_prec_day+1):nb_cars
        RC_value = "0"
        HPRC_value = "0"
        for option in 1:nb_HPRC
            RC_value = string(Int(RC_flag[car, option])) * RC_value
            HPRC_value = string(Int(RC_flag[car, option])) * HPRC_value
        end
        for option in (nb_HPRC+1):nb_LPRC
            RC_value = string(Int(RC_flag[car, option])) * RC_value
        end
        RC_key = parse(Int, string(RC_value), base = 2)
        HPRC_key = parse(Int, string(HPRC_value), base = 2)

        if !haskey(RC_cars, RC_key)
            RC_cars[RC_key] = [car]
        else
            push!(RC_cars[RC_key], car)
        end
        if !haskey(HPRC_cars, HPRC_key)
            HPRC_cars[HPRC_key] = [car]
        else
            push!(HPRC_cars[HPRC_key], car)
        end
    end

    return Instance(
            HPRC_rank, LPRC_rank, PCB_rank,                            # objectives file
            nb_paint_limitation,                                       # paint file
            RC_p, RC_q, nb_HPRC, nb_LPRC,                              # ratio file
            RC_flag, color_code, nb_late_prec_day, nb_cars,            # vehicles file
            RC_cars, HPRC_cars
        )
end


##### Old parser with dependencies:
#="""
    parser_old(instance_name::String, instance_type::String, path_folder::String=string(@__DIR__)*"/../data/Instances_")

Returns return the instance of type instance_type parsed form the files in path_folder. Uses CSV and DataFrames
"""
function parser_old(instance_name::String, instance_type::String, path_folder::String=string(@__DIR__)*"/../data/Instances_")
    path = path_folder * instance_type * "/" * instance_name * "/"
    # table of data
    df_optimisation = CSV.File(path * OPTIMISATION_FILE_NAME, delim=';', silencewarnings=true) |> DataFrame
    df_paint = CSV.File(path * PAINT_FILE_NAME, delim=';', silencewarnings=true) |> DataFrame
    df_ratio = CSV.File(path * RATIO_FILE_NAME, delim=';', silencewarnings=true) |> DataFrame
    df_vehicles = CSV.File(path * VEHICLES_FILE_NAME, delim=';', silencewarnings=true) |> DataFrame

    # There is a fictive last column
    df_optimisation = df_optimisation[:,1:min(2, end)]
    df_paint = df_paint[:, 1:min(1, end)]
    df_ratio = df_ratio[:, 1:min(3, end)]
    df_vehicles = df_vehicles[:, 1:min((4+size(df_ratio)[1]), end)]

    # Avoid lines with missing value that are not usable.
    df_optimisation = df_optimisation[completecases(df_optimisation), :]
    df_paint = df_paint[completecases(df_paint), :]
    df_ratio = df_ratio[completecases(df_ratio), :]
    df_vehicles = df_vehicles[completecases(df_vehicles), :]
    #dropmissing!(df_optimisation, :rank)
    #dropmissing!(df_paint, :limitation)
    #dropmissing!(df_ratio, :Ratio)
    #dropmissing!(df_vehicles, :SeqRank)

    # Rank parsing
    temp = findall(e -> occursin("high", e), df_optimisation[:, 2])
    HPRC_rank = df_optimisation[:, 1][temp[1]]

    temp = findall(e -> occursin("low", e), df_optimisation[:, 2])
    if length(temp) > 0
        LPRC_rank = df_optimisation[:, 1][temp[1]]
    else
        LPRC_rank = -1
    end

    temp = findall(e -> occursin("paint", e), df_optimisation[:, 2])
    PCB_rank = df_optimisation[:, 1][temp[1]]

    # Paint limitation
    nb_paint_limitation = df_paint.limitation[1]

    # Ratio data
    n, m = size(df_ratio)
    RC_p = Array{Int, 1}()
    RC_q = Array{Int, 1}()
    nb_high = 0
    for i in 1:n
        a, b = parse.(Int, split(df_ratio.Ratio[i], "/"))
        push!(RC_p, a)
        push!(RC_q, b)
        if df_ratio.Prio[i] == 1
            nb_high += 1
        end
    end
    nb_low = n - nb_high

    # vehicles data
    RC_flag = Array{Bool, 2}(df_vehicles[:, 5:5+n-1])

    color_code = Array{Int, 1}(df_vehicles[:, 4])

    nb_late_prec_day = findall(x -> x == 1, df_vehicles[:, 2])[1] - 1

    return Instance(
            HPRC_rank, LPRC_rank, PCB_rank,                            # objectives file
            nb_paint_limitation,                                       # paint file
            RC_p, RC_q, nb_high, nb_low,                               # ratio file
            RC_flag, color_code, nb_late_prec_day, length(color_code)  # vehicles file
        )
end
=#
