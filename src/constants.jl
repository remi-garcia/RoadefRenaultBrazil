#-------------------------------------------------------------------------------
# File: constants.jl
# Description:
# Date: October 31, 2019
# Author: Jonathan Fontaine, Killian Fretaud, Rémi Garcia,
#         Boualem Lamraoui, Benoît Le Badezet, Benoit Loger
#-------------------------------------------------------------------------------

const WEIGHTS_OBJECTIVE_FUNCTION = [1000, 1, 1000000]

# TIME
const TIME_LIMIT = 60.0
const TIME_PART_ILS = 0.9
const TIME_PART_VNS_LPRC = 0.96
const TIME_PART_VNS_PCC = 1 # Unused for now

# ILS-HPRC
const ALPHA_ILS = 25
const BETA_ILS = 50
const STOPPING_CRITERIA_ILS_HPRC = 3
const NBCAR_PERTURBATION = 5
const NBCAR_DIVERSIFICATION = 50

# VNS-LPRC
const VNS_LPRC_MAX_NON_IMPROVEMENT = 150
const VNS_LPRC_MIN_INSERT = 3
const VNS_LPRC_MAX_INSERT = 8
const VNS_LPRC_MIN_EXCHANGE = 5
const VNS_LPRC_MAX_EXCHANGE = 12

# VNS-PCC
const VNS_PCC_MIN_INSERT = 2
const VNS_PCC_MAX_INSERT = 8
const VNS_PCC_MIN_EXCHANGE = 2
const VNS_PCC_MAX_EXCHANGE = 10
const VNS_PCC_MINMAX = [(VNS_PCC_MIN_INSERT, VNS_PCC_MAX_INSERT), (VNS_PCC_MIN_EXCHANGE, VNS_PCC_MAX_EXCHANGE)]

# Files names
const INSTANCES = Dict{String, Array{String, 1}}(
    "A" => [
        "022_3_4_EP_RAF_ENP",
        "022_3_4_RAF_EP_ENP",
        "024_38_3_EP_ENP_RAF",
        "024_38_3_EP_RAF_ENP",
        "024_38_5_EP_ENP_RAF",
        "024_38_5_EP_RAF_ENP",
        "025_38_1_EP_ENP_RAF",
        "025_38_1_EP_RAF_ENP",
        "039_38_4_EP_RAF_ch1",
        "039_38_4_RAF_EP_ch1",
        "048_39_1_EP_ENP_RAF",
        "048_39_1_EP_RAF_ENP",
        "064_38_2_EP_RAF_ENP_ch1",
        "064_38_2_EP_RAF_ENP_ch2",
        "064_38_2_RAF_EP_ENP_ch1",
        "064_38_2_RAF_EP_ENP_ch2"
    ],
    "B" => [
        "022_EP_ENP_RAF_S22_J1",
        "022_EP_RAF_ENP_S22_J1",
        "022_RAF_EP_ENP_S22_J1",
        "023_EP_ENP_RAF_S23_J3",
        "023_EP_RAF_ENP_S23_J3",
        "023_RAF_EP_ENP_S23_J3",
        "024_V2_EP_ENP_RAF_S22_J1",
        "024_V2_EP_RAF_ENP_S22_J1",
        "024_V2_RAF_EP_ENP_S22_J1",
        "025_EP_ENP_RAF_S22_J3",
        "025_EP_RAF_ENP_S22_J3",
        "025_RAF_EP_ENP_S22_J3",
        "028_ch1_EP_ENP_RAF_S22_J2",
        "028_ch1_EP_RAF_ENP_S22_J2",
        "028_ch1_RAF_EP_ENP_S22_J2",
        "028_ch2_EP_ENP_RAF_S23_J3",
        "028_ch2_EP_RAF_ENP_S23_J3",
        "028_ch2_RAF_EP_ENP_S23_J3",
        "029_EP_ENP_RAF_S21_J6",
        "029_EP_RAF_ENP_S21_J6",
        "029_RAF_EP_ENP_S21_J6",
        "035_ch1_EP_ENP_RAF_S22_J3",
        "035_ch1_EP_RAF_ENP_S22_J3",
        "035_ch1_RAF_EP_ENP_S22_J3",
        "035_ch2_EP_ENP_RAF_S22_J3",
        "035_ch2_EP_RAF_ENP_S22_J3",
        "035_ch2_RAF_EP_ENP_S22_J3",
        "039_ch1_EP_ENP_RAF_S22_J4",
        "039_ch1_EP_RAF_ENP_S22_J4",
        "039_ch1_RAF_EP_ENP_S22_J4",
        "039_ch3_EP_ENP_RAF_S22_J4",
        "039_ch3_EP_RAF_ENP_S22_J4",
        "039_ch3_RAF_EP_ENP_S22_J4",
        "048_ch1_EP_ENP_RAF_S22_J3",
        "048_ch1_EP_RAF_ENP_S22_J3",
        "048_ch1_RAF_EP_ENP_S22_J3",
        "048_ch2_EP_ENP_RAF_S22_J3",
        "048_ch2_EP_RAF_ENP_S22_J3",
        "048_ch2_RAF_EP_ENP_S22_J3",
        "064_ch1_EP_ENP_RAF_S22_J3",
        "064_ch1_EP_RAF_ENP_S22_J3",
        "064_ch1_RAF_EP_ENP_S22_J3",
        "064_ch2_EP_ENP_RAF_S22_J4",
        "064_ch2_EP_RAF_ENP_S22_J4",
        "064_ch2_RAF_EP_ENP_S22_J4"
    ],
    "X" => [
        "022_RAF_EP_ENP_S49_J2",
        "023_EP_RAF_ENP_S49_J2",
        "024_EP_RAF_ENP_S49_J2",
        "025_EP_ENP_RAF_S49_J1",
        "028_CH1_EP_ENP_RAF_S50_J4",
        "028_CH2_EP_ENP_RAF_S51_J1",
        "029_EP_RAF_ENP_S49_J5",
        "034_VP_EP_RAF_ENP_S51_J1_J2_J3",
        "034_VU_EP_RAF_ENP_S51_J1_J2_J3",
        "035_CH1_RAF_EP_S50_J4",
        "035_CH2_RAF_EP_S50_J4",
        "039_CH1_EP_RAF_ENP_S49_J1",
        "039_CH3_EP_RAF_ENP_S49_J1",
        "048_CH1_EP_RAF_ENP_S50_J4",
        "048_CH2_EP_RAF_ENP_S49_J5",
        "064_CH1_EP_RAF_ENP_S49_J1",
        "064_CH2_EP_RAF_ENP_S49_J4",
        "655_CH1_EP_RAF_ENP_S51_J2_J3_J4",
        "655_CH2_EP_RAF_ENP_S52_J1_J2_S01_J1"
    ]
)
