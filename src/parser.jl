#=
This file contains all function used to parse the data and return the data to an
appropriate format to be compute.

Link of the data : http://www.roadef.org/challenge/2005/fr/sujet.php
The data should be in ../data/Instances_Type/name_instance/
There is 3 types of instances labeled A, B and X, so folders
should be named Instances_A/, Instances_B/, and Instances_X/.
=#

# Library used to read CSV file, that is the format of data.
using CSV

# Library importing the DataFrame type that is easier to manipulate.
using DataFrames

# Constant of the problem
const OPTIMISATION_FILE_NAME = "optimization_objectives.txt"
const PAINT_FILE_NAME = "paint_batch_limit.txt"
const RATIO_FILE_NAME = "ratios.txt"
const VEHICLES_FILE_NAME = "vehicles.txt"

# An Instance structure that is used to format data as we want.
struct Instances
    # objectif function
    HPRC_rank::Int
    LPRC_rank::Int # If there is no LPRC, LPRC_rank = -1
    PCB_rank::Int
    # paint limitation
    nb_paint_limitation::Int
    # ratio constraint
    HPRC_p::Array{Float64, 1}
    HPRC_q::Array{Float64, 1}
    LPRC_p::Array{Float64, 1}
    LPRC_q::Array{Float64, 1}
    nb_HPRC::Int
    nb_LPRC::Int
    # sequence vehicle data
    HPRC_flag::Array{Bool, 2}
    LPRC_flag::Array{Bool, 2}
    color_code::Array{Int, 1}
    # Number of vehicles that weren't build the precedet day.
    nb_late_prec_day::Int # Usage 1:nb_late_prec_day give the list of index of those vehicles.
end

# This function is used to read data of an instance from all files, and agregate into an Instance structure.
function parser(instance_name::String, instance_type::String, path_folder::String="../data/Instances_")
    path = path_folder * instance_type * "/" * instance_name * "/"
    # table of data
    df_optimisation = CSV.File(path * OPTIMISATION_FILE_NAME, delim=';',silencewarnings=true) |> DataFrame
    df_paint = CSV.File(path * PAINT_FILE_NAME, delim=';',silencewarnings=true) |> DataFrame
    df_ratio = CSV.File(path * RATIO_FILE_NAME, delim=';',silencewarnings=true) |> DataFrame
    df_vehicles = CSV.File(path * VEHICLES_FILE_NAME, delim=';',silencewarnings=true) |> DataFrame

    # Rank parsing
    temp = findall(e -> occursin("high", e), df_optimisation[!, 2])
    HPRC_rank = df_optimisation[!, 1][temp[1]]

    temp = findall(e -> occursin("low", e), df_optimisation[!, 2])
    if length(temp) > 0
        LPRC_rank = df_optimisation[!, 1][temp[1]]
    else LPRC_rank = -1 end

    temp = findall(e -> occursin("paint", e), df_optimisation[!, 2])
    PCB_rank = df_optimisation[!, 1][temp[1]]

    # Paint limitation
    nb_paint_limitation = df_paint.limitation[1]

    # Ratio data
    n, m = size(df_ratio)
    HPRC_p = Array{Float64, 1}()
    HPRC_q = Array{Float64, 1}()
    LPRC_p = Array{Float64, 1}()
    LPRC_q = Array{Float64, 1}()
    for i in 1:n
        a, b = parse.(Float64, split(df_ratio.Ratio[i], "/"))
        if (df_ratio.Prio[i] == 1)
            push!(HPRC_p, a)
            push!(HPRC_q, b)
        else
            push!(LPRC_p, a)
            push!(HPRC_q, b)
        end
    end

    nb_high = length(HPRC_p)
    nb_low = length(LPRC_p)

    # vehicles data
    if nb_high > 0
        HPRC_flag = Array{Bool, 2}(df_vehicles[!, 5:5+nb_high-1])
    else
        HPRC_flag = Array{Bool, 2}()
    end

    if nb_low > 0
        LPRC_flag = Array{Bool, 2}(df_vehicles[!, 5+nb_high:5+nb_high+nb_low-1])
    else
        LPRC_flag = Array{Bool, 2}()
    end

    color_code = Array{Int, 1}(df_vehicles[!, 4])

    nb_late_prec_day = findall(x -> x == 1, df_vehicles[!, 2])[1] - 1

    return Instances(
            HPRC_rank, LPRC_rank, PCB_rank,                     # objectives file
            nb_paint_limitation,                                # paint file
            HPRC_p, HPRC_q, LPRC_p, LPRC_q, nb_high, nb_low,    # ratio file
            HPRC_flag, LPRC_flag, color_code, nb_late_prec_day  # vehicles file
        )
end
