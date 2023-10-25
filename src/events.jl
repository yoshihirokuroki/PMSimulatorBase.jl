using SciMLBase
using PMParameterized
function checkRateTinf(amt::Union{Float64, Vector{Float64}}, rate::Union{Float64,Vector{Float64}, Nothing}, tinf::Union{Float64,Vector{Float64}, Nothing})
    if isnothing(rate) && !isnothing(tinf)
        rate = amt ./ tinf
    elseif !isnothing(rate) && isnothing(tinf)
        tinf = amt./rate
    elseif !isnothing(rate) && !isnothing(tinf)
        if rate != amt./tinf
            error("If rate and infusion time are specified, they must result in amt being delivered")
        end
    end
    return (rate, tinf)
end


Base.@kwdef struct PMInput
    time::Float64
    amt::Float64
    input::Symbol
    tinf::Union{Float64, Nothing} = nothing
    addl::Int64 = 0
    ii::Float64 = 0.0
    rate::Union{Float64, Nothing} = nothing
    _dataframe::Bool = false
    function PMInput(time, amt, input, tinf, addl, ii, rate, _dataframe = false)
        rate, tinf = checkRateTinf(amt, rate, tinf)
        # tinf = isnothing(tinf) ? [tinf] : tinf # Make tinf a Vector{Nothing} for the checks below
        if addl>0.0 && iszero(ii)
            error("ii must be greater than 0.0 for additional doses")
        end
        # if length(time)>1 && any(i -> length(i) != length(time), [amt, tinf, addl]) && all(i -> length(i) != 1,[amt,tinf,addl])
        #     error("Invalid dimensions of time, and one of [amt, tinf, input, addl]")
        # elseif length(time) == 1 && any(i -> length(i) > 1, [amt, tinf, addl])
        #     error("Invalid dimensions of time, and one of [amt, tinf, input, addl]")
        # else
        tinf = tinf == [nothing] ? nothing : tinf # convert back to nothing
        new(time, amt, input, tinf, addl, ii, rate, _dataframe)
        # end
    end
end

Base.@kwdef struct PMUpdate
    time::Float64
    quantity::Symbol
    value::Float64
    _dataframe::Bool = false
    function PMUpdate(time, quantity, value, _dataframe = false)
        if length(time) != length(value)
            error("Time and value vectors must be of equal length")
        else
            new(time, quantity, value, _dataframe)
        end
    end
end

Base.@kwdef struct PMInstance
    inputs::Vector{PMInput}
    updates::Vector{PMUpdate}
    ID::Union{Int64, Symbol}
end


Base.@kwdef struct PMEnsemble
    instances::Vector{PMInstance}
    _solution::Union{Nothing, Vector{PMParameterized.PMSolution}}
end



