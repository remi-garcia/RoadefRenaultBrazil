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
end

# This function is used to read data of an instance from all files, and agregate into an Instance structure.
function parser(instance_name::String, instance_type::String, path_folder::String=string(@__DIR__)*"/../data/Instances_")
    path = path_folder * instance_type * "/" * instance_name * "/"
    #instdir = "/home/lamraoui/Projets/momh-roadef2005/data/Instances_X/655_CH2_EP_RAF_ENP_S52_J1_J2_S01_J1/optimization_objectives.txt"

    #Lecture  OPTIMISATION_FILE_NAME
    HPRC_rank = 0
    LPRC_rank = 0
    PCB_rank = 0
    f = open(path * OPTIMISATION_FILE_NAME)
    line = readline(f)
    for line in eachline(f)
        pointeurLine = rsplit(line , ";")
        object_name = rsplit(pointeurLine[2] , "_")
        if object_name[1] == "high"
            HPRC_rank = parse(Int , pointeurLine[1])
        end
        if object_name[1] == "low"
            LPRC_rank = parse(Int , pointeurLine[1])
        end
        if object_name[1] == "paint"
            PCB_rank = parse(Int,pointeurLine[1])
        end
    end
    close(f)

    #Lecture PAINT_FILE_NAME
    nb_paint_limitation = 0
    f = open(path * PAINT_FILE_NAME)
    line = readline(f)
    for line in eachline(f)
         pointeurLine = split(line,";")
         nb_paint_limitation = parse(Int, pointeurLine[1])
    end
    close(f)

    #Lecture RATIO_FILE_NAME
    indice_nb_HPRC = 0
    indice_nb_LPRC = 0
    RC_p = Array{Int,1}()
    RC_q = Array{Int,1}()
    f = open(path * RATIO_FILE_NAME)
    line = readline(f)
    for line in eachline(f)
        pointeurLine = rsplit(line,";")
        ratio = split(pointeurLine[1],"/")
        push!(RC_p,parse(Int,ratio[1]))
        push!(RC_q,parse(Int,ratio[2]))
        if pointeurLine[2] == "1"
            indice_nb_HPRC += 1
        end
        if pointeurLine[2] == "0"
            indice_nb_LPRC += 1
        end
    end
    close(f)
    nb_HPRC = indice_nb_HPRC
    nb_LPRC = indice_nb_LPRC

    #Lecture VEHICLES_FILE_NAME
    color_code = Array{Int,1}()
    nb_cars = 0
    day = 0
    ligne =1
    indice = 0
    nb_RC = nb_HPRC + nb_LPRC
    f = open(path*VEHICLES_FILE_NAME)
    line = readline(f)
    for line in eachline(f)
        nb_cars += 1
    end
    close(f)
    RC_flag = Array{Bool, 2}(undef, nb_cars, nb_RC) # nb_RC = nb_LPRC + nb_HPRC
    nb_late_prec_day = 0
    f = open(path*VEHICLES_FILE_NAME)
    line = readline(f)
    for line in eachline(f)
        pointeurLine = rsplit(line,";")
        date = split(pointeurLine[1]," ")
        if date[3] != day
            day = date[3]
            nb_late_prec_day = nb_cars
        end
       for colonne in 5:length(pointeurLine)-1
            RC_flag[ligne , colonne - 4] = parse(Int,pointeurLine[colonne])
        end
        nb_cars += 1
        push!(color_code ,parse(Int,pointeurLine[4]))
        ligne += 1
    end
    close(f)
    return Instance(
            HPRC_rank, LPRC_rank, PCB_rank,                            # objectives file
            nb_paint_limitation,                                       # paint file
            RC_p, RC_q, nb_HPRC, nb_LPRC,                               # ratio file
            RC_flag, color_code, nb_late_prec_day,nb_cars               # vehicles file
        )
end
