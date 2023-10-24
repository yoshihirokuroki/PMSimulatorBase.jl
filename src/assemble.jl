using PMEvents
using ParameterizedModels
using ModelingToolkit
using SciMLBase
using DiffEqCallbacks

InputOrUpdate = Union{MMInput, MMUpdate}



indexof(sym::Symbol, syms) = findfirst(isequal(sym), syms)

function getMTKindex(mdl::ParameterizedModels.PMModel, sym::Symbol)
    psyms = Symbol.(parameters(mdl._sys))
    ssyms = [x.metadata[ModelingToolkit.VariableSource][2] for x in states(mdl._sys)]
    pindex = indexof(sym, psyms)
    sindex = indexof(sym, ssyms)
    if !isnothing(pindex) && !isnothing(sindex)
        error("Found $sym in parameters and states, cannot get index")
    elseif isnothing(pindex) && isnothing(sindex)
        error("Cannot locate $sym in parameters or states")
    end
    indices = [pindex, sindex]
    index = indices[indices.!=nothing][1] # Get only the non-nothing index
    return index
end




function updateParameterOrState!(mdl::ParameterizedModels.PMModel, sym::Symbol, val::Float64)
    if sym in mdl.parameters.names
        mdl.parameters[sym] = val
    elseif sym in mdl.states.names
        mdl.states[sym] = val
    else
        error("Cannot find $sym in parameters or states")
    end
end


function generateInputCB(mdl::ParameterizedModels.PMModel, tstart::Float64, tinf::Union{Float64,Nothing}, amt::Float64, input::Symbol)
    # cbset = CallbackSet()
    cbset = DiscreteCallback[]
    if tstart == 0.0
        updateParameterOrState!(mdl, input, amt)
    else
        index = getMTKindex(mdl, input)
        # affectstart!(integrator) = integrator.u[index] += amt/tinf
        if tinf > 0.0
            # println(index)
            # affecton
            cbstartinf = PresetTimeCallback(tstart, (integrator) -> integrator.p[index] =  integrator.p[index] + amt/tinf)
            push!(cbset, cbstartinf)
        elseif tinf < 0.0
            error("Cannot have negative infusion time")
        elseif tinf == 0.0
            cbstartbolus = PresetTimeCallback(tstart, (integrator) -> integrator.u[index] += amt)
            push!(cbset, cbstartbolus)
        else
            error("Some other error")
        end
    end
    # Infusion end
    if tinf != 0.0
        # affectoff(integrator) = integrator.p[index] = integrator.p[index] - amt/tinf
        cbend = PresetTimeCallback(tstart+tinf, (integrator) -> integrator.p[index] = integrator.p[index] - amt/tinf)
        push!(cbset, cbend)
    end
    return cbset
end


    






function collect_evs(evs::Union{InputOrUpdate, Vector{MMInput}, Vector{MMUpdate}}, mdl::ParameterizedModels.PMModel)
    if isa(evs, InputOrUpdate)
        evs::Vector{InputOrUpdate} = [evs]
    end
    cbset = DiscreteCallback[]
    for ev in evs
        if isa(ev, MMInput)
            t = ev.time
            amt = ev.amt
            tinf = ev.tinf
            input = ev.input
            addl = ev.addl
            ii = ev.ii
            # tinf = isnothing(tinf) ? [nothing] : tinf # Convert to vector for below
            # tinf = [isnothing(x) ? 0.0 : x for x in tinf]
            amt = length(amt) == 1 ? amt * ones(length(t)) : amt
            if !isnothing(tinf)
                tinf = length(tinf) == 1 ? tinf * ones(length(t)) : tinf
            else
                tinf = [0.0 for i = 1:lastindex(t)]
            end

            for (i, ti) in enumerate(t)
                cbset_i = generateInputCB(mdl, ti, tinf[i], amt[i],input)
                append!(cbset, cbset_i)
            end
        end
    end
    return CallbackSet(cbset...)
end

        

    