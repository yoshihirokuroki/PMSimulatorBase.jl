function buildInstance(evs::Vector{PMEvent}, ID::Union{Int64, Symbol})
    ev_inputs = PMInput[]
    ev_updates = PMUpdate[]
    for ev in evs
        if isa(ev, PMInput)
            push!(ev_inputs, ev)
        elseif ia(ev, PMUpdate)
            push!(ev_updates, ev)
        else
            error("Ev $ev not recognized as an Input or an Update")
        end
    end
    return PMInstance(inputs = ev_inputs, updates = ev_updates, ID = ID)
end

function combineInstances(instances::Vector{PMInstance})
    return PMEvents(instances = instances)
end

