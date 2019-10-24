
include("parser.jl")

mutable struct Solution
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
        collect(1:nC),
        zeros(Int,nO,nC),
        zeros(Int,nO,nC),
        zeros(Int,nO,nC)
    )
end

# Build an initial
function init_solution(nom_fichier::String, type_fichier::String)
    # Read in data files
    instance = parser(nom_fichier, type_fichier)

    # For following algorithms, let:
    n = size(instance.HPRC_flag)[1]
    m = length(instance.HPRC) + length(instance.LPRC)
    solution = Solution(n,m)
    return solution
end
