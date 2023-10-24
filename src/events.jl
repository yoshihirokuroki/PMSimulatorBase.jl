using SciMLBase
using ParameterizedModels
function checkRateTinf(amt::Union{Float64, Vector{Float64}}, rate::Union{Float64,Vector{Float64}, Nothing}, tinf::Union{Float64,Vector{Float64}, Nothing})
    if isnothing(rate) && !isnothing(tinf)
        rate = amt ./ tinf
    elseif !isnothing(rate) && isnothing(tinf)
        tinf = amt./rate
    elseif !isnothing(rate) && !isnothing(tinf)
        error("Cannot specify a rate and infusion time")
    end
    return (rate, tinf)
end


Base.@kwdef struct MMInput
    time::Union{Float64, Vector{Float64}}
    amt::Union{Float64, Vector{Float64}}
    input::Symbol
    tinf::Union{Float64, Vector{Float64}, Nothing} = nothing
    addl::Int64 = 0
    ii::Float64 = 0.0
    rate::Union{Float64, Vector{Float64}, Nothing} = nothing
    function MMInput(time, amt, input, tinf, addl, ii, rate)
        rate, tinf = checkRateTinf(amt, rate, tinf)
        tinf = isnothing(tinf) ? [tinf] : tinf # Make tinf a Vector{Nothing} for the checks below
        if length(time)>1 && any(i -> length(i) != length(time), [amt, tinf, addl]) && all(i -> length(i) != 1,[amt,tinf,addl])
            error("Invalid dimensions of time, and one of [amt, tinf, input, addl]")
        elseif length(time) == 1 && any(i -> length(i) > 1, [amt, tinf, addl])
            error("Invalid dimensions of time, and one of [amt, tinf, input, addl]")
        else
            tinf = tinf == [nothing] ? nothing : tinf # convert back to nothing
            new(time, amt, input, tinf, addl, ii, rate)
        end
    end
end

# What do we do for dose and update of state occuring at the same time --> Which comes first?
Base.@kwdef struct MMUpdate
    time::Union{Float64, Vector{Float64}}
    quantity::Symbol
    value::Union{Float64, Vector{Float64}}
    function MMUpdate(time, quantity, value)
        if length(time) != length(value)
            error("Time and value vectors must be of equal length")
        else
            new(time, quantity, value)
        end
    end
end

Base.@kwdef struct MMInstance
    inputs::Vector{MMInput}
    updates::Vector{MMUpdate}
    ID::Union{Int64, Symbol}
    callbacks::CallbackSet
    _solution::ParameterizedModels.PMSolution
end

Base.@kwdef struct MMEnsemble
    instances::Vector{MMInstance}
    _solution::Vector{ParameterizedModels.PMSolution}
end



