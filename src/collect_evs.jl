
function collect_evs(evs, mdl::PMModel)
    cbset = DiscreteCallback[]
    for ev in evs
        if isa(ev, PMInput) && !(ev._dataframe) && ev.input ∉ (mdl.parameters.names..., mdl.states.names..., mdl._inputs.names...)
            error("Error creating event for $(ev.input). $(ev.input) not found in model states, parameters or equations ")
        elseif isa(ev, PMUpdate) && !(ev._dataframe) && ev.quantity ∉ (mdl.parameters.names..., mdl.states.names..., mdl._inputs.names...)
            error("Error creating event for $(ev.quantity). $(ev.quantity) not found in model states, parameters or equations ")
        else
            if isa(ev, PMInput) && ev.input ∈ (mdl.parameters.names..., mdl.states.names..., mdl._inputs.names...)
                t = ev.time
                amt = ev.amt
                tinf = ev.tinf
                input = ev.input
                addl = ev.addl
                ii = ev.ii

                # Check and make sure that input exists in the state/equation names
                if input ∉ keys(mdl._inputs.sym_to_val)
                    error("Cannot find input $input in model states/equations")
                else
                    idx = mdl._inputs.sym_to_val[input]
                    inputP = PMParameterizedBase.getSymbolicName(mdl._inputs.values[idx].first)
                end

                if !iszero(addl)
                    amt = [amt for i in 1:(addl+1)]
                    tinf = [isnothing(tinf) ? 0.0 : tinf for i in 1:(addl+1)]
                    t = [t + (ii * (i-1)) for i in 1:addl]
                    if mdl.tspan[2] < t[end]
                        mdl.tspan = (mdl.tspan[1], t[end]+ii)
                    end
                else
                    tinf = isnothing(tinf) ? 0.0 : tinf
                end
                for (i, ti) in enumerate(t)
                    cbset_i = generateInputCB(mdl, ti, tinf[i], amt[i], inputP, input)
                    append!(cbset, cbset_i)
                end
            elseif isa(ev, PMUpdate) && ev.quantity ∈ (mdl.parameters.names..., mdl.states.names..., mdl._inputs.names...)
                cb_i = generateUpdateCB(mdl, ev)
                if !isnothing(cb_i)
                    push!(cbset, cb_i)
                end
            # else
                # println(ev)
                # error("Something went wrong")
            end
        end
    end
    return CallbackSet(cbset...)
end