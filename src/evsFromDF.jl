using TidierData
using DataFrames
function df2evs(df::AbstractDataFrame)
    # do conversions of column names in input data
    if "AMT" in names(idf); rename!(idf, :AMT => :amt); end
    if "TIME" in names(idf); rename!(idf, :TIME => :time); end
    if "CMT" in names(idf); rename!(idf, :CMT => :cmt); end
    if "EVID" in names(idf); rename!(idf, :EVID => :evid); end
    if "RATE" in names(idf); rename!(idf, :RATE => :rate); end
    if "TINF" in names(idf); rename!(idf, :TINF => :tinf); end
    if "II" in names(idf); rename!(idf, :II => :ii); end
    if "ADDL" in names(idf); rename!(idf, :ADDL => :addl); end
    if "id" in names(idf); rename!(idf, :id => :ID); end

    if !("cmt" in names(idf)); idf[:,:cmt] .= 1; end
    if !("ii" in names(idf)); idf[:,:ii] .= 0.0; end
    if !("addl" in names(idf)); idf[:,:addl] .= 0; end
    if !("rate" in names(idf)); idf[:,:rate] .= 0.0; end
    if !("F" in names(idf)); warning("F not currently supported"); idf[:,:F] .= 1.0; end
    if !("alag" in names(idf)); warning("alag not currently supported"); idf[:,:alag] .= 0.0; end
    if !("ss" in names(idf)); warning("ss not currently supported"); idf[:,:ss] .= 0.0; end

    if "tinf" ∉ names(idf)
        for row in eachrow(idf)
            if row.rate != 0.0
                row.tinf = row.amt/row.rate
            end
        end
    elseif "tinf" ∈ names(idf)
        for row in eachrow(idf)
            if row.rate != 0.0
                error("Cannot specify both a rate and infusion time")
            else
                row.rate = row.amt / row.tinf
            end
        end
    end
                

    params_in_df = Symbol.(names(df)[Symbol.(names(df)) ∉ [:amt, :time, :cmt, :evid, :rate, :ii, :addl, :id, :F, :alag, :ss]])
    ids = unique(df.id)
    instancevec = PMInstance[]
    for idtmp in ids
        df_id = @chain df begin
            @filter(id == idtmp)
        end
        ev_inputs_id = PMInput[]
        ev_updates_id = PMUpdate[]
        for row in eachrow(df_id)
            if row.evid == 1
                push!(ev_inputs_id, PMInput(time = row.time, amt = row.amt, input = row.input, tinf = row.tinf, addl = row.addl, ii = row.ii, rate = row.rate))
                for param_i in params_in_df
                    push!(ev_updates_id, PMUpdate(time = row.time, quantity = param_i, value = row[param_i]))
                end
            elseif row.evid == 0
                for param_i in params_in_df
                    push!(ev_updates_id, PMUpdate(time = row.time, quantity = param_i, value = row[param_i]))
                end
            elseif row.evid in [2,3,4]
                erorr("EVIDs 2, 3, and 4 not currently supported")
            end
        end
        instance_i = PMInstance(inputs = ev_inputs_id, updates = ev_updates_id, ID = idtmp)
        push!(instancevec, instance_i)
    end
    out = PMEnsemble(instances = instancevec, _solution = nothing)
    return out
end

    





end