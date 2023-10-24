using PMSimulator
using PMParameterized
using ModelingToolkit
using SciMLBase
using DiffEqCallbacks

InputOrUpdate = Union{PMInput, PMUpdate}



indexof(sym::Symbol, syms) = findfirst(isequal(sym), syms)

function getMTKindex(mdl::PMParameterized.PMModel, sym::Symbol)
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




function updateParameterOrState!(mdl::PMParameterized.PMModel, sym::Symbol, val::Float64)
    if sym in mdl.parameters.names
        mdl.parameters[sym] = val
    elseif sym in mdl.states.names
        mdl.states[sym] = val
    else
        error("Cannot find $sym in parameters or states")
    end
end


function generateInputCB(mdl::PMParameterized.PMModel, tstart::Float64, tinf::Union{Float64,Nothing}, amt::Float64, input::Symbol)
    cbset = DiscreteCallback[]
    if tstart == 0.0
        updateParameterOrState!(mdl, input, amt)
    else
        index = getMTKindex(mdl, input)
        if tinf > 0.0
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
        cbend = PresetTimeCallback(tstart+tinf, (integrator) -> integrator.p[index] = integrator.p[index] - amt/tinf)
        push!(cbset, cbend)
    end
    return cbset
end

function generateUpdateCB(mdl::PMParameterized.PMModel, update::PMUpdate)
    time = update.time
    quantity = update.quantity
    value = update.value
    if time == 0.0
        updateParameterOrState!(mdl, quantity, value)
        return nothing!
    else
        index = getMTKindex(mdl, in)
        cbtmp = PresetTimeCallback(time, (integrator) -> integrator.p[index] = value)
        # push!(cbset, cbtmp)
        return cbtmp
    end
end




function collect_evs(evs::Union{InputOrUpdate, Vector{PMInput}, Vector{PMUpdate}}, mdl::PMParameterized.PMModel)
    if isa(evs, InputOrUpdate)
        evs::Vector{InputOrUpdate} = [evs]
    end
    cbset = DiscreteCallback[]
    for ev in evs
        if isa(ev, PMInput)
            t = ev.time
            amt = ev.amt
            tinf = ev.tinf
            input = ev.input
            addl = ev.addl
            ii = ev.ii

            if !iszero(addl)
                amt = [amt for i in 1:addl]
                tinf = [isnothing(tinf) ? 0.0 : tinf for i in 1:addl]
                t = [t + (ii * (i-1)) for i in 1:addl]
            end

            for (i, ti) in enumerate(t)
                cbset_i = generateInputCB(mdl, ti, tinf[i], amt[i], input)
                append!(cbset, cbset_i)
            end
        elseif isa(ev, PMUpdate)
            cb_i = generateUpdateCB(mdl, PMUpdate)
            push!(cbset, cb_i)
        else
            error("Something went wrong")
        end
    end
    return CallbackSet(cbset...)
end


        

    