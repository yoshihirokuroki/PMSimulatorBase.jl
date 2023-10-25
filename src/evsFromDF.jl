using TidierData
using DataFrames
function df2evs(dfin::AbstractDataFrame)
    df = copy(dfin)
    # do conversions of column names in input data
    if "AMT" in names(df); rename!(df, :AMT => :amt); end
    if "TIME" in names(df); rename!(df, :TIME => :time); end
    if "CMT" in names(df); rename!(df, :CMT => :cmt); end
    if "EVID" in names(df); rename!(df, :EVID => :evid); end
    if "RATE" in names(df); rename!(df, :RATE => :rate); end
    if "TINF" in names(df); rename!(df, :TINF => :tinf); end
    if "II" in names(df); rename!(df, :II => :ii); end
    if "ADDL" in names(df); rename!(df, :ADDL => :addl); end
    if "id" in names(df); rename!(df, :id => :ID); end

    if !("cmt" in names(df)); df[:,:cmt] .= 1; end
    if !("ii" in names(df)); df[:,:ii] .= 0.0; end
    if !("addl" in names(df)); df[:,:addl] .= 0; end
    if !("rate" in names(df)); df[:,:rate] .= 0.0; end
    if !("F" in names(df)); @warn "F not currently supported" ; df[:,:F] .= 1.0; end
    if !("alag" in names(df)); @warn "alag not currently supported" ; df[:,:alag] .= 0.0; end
    if !("ss" in names(df)); @warn "ss not currently supported" ; df[:,:ss] .= 0.0; end

    if "tinf" ∉ names(df)
        df[!,:tinf] .= 0.0
        for row in eachrow(df)
            if row.rate != 0.0
                row.tinf = row.amt/row.rate
            end
        end

    elseif "tinf" ∈ names(df)
        for row in eachrow(df)
            if row.rate != 0.0
                error("Cannot specify both a rate and infusion time")
            else
                row.rate = row.amt / row.tinf
            end
        end
    end
                


    params_in_df = Symbol[]
    for nm in Symbol.(names(df))
        if nm ∉ [:amt, :time, :cmt, :evid, :rate, :ii, :addl, :ID, :F, :alag, :ss, :input]
            push!(params_in_df, nm)
        end
    end
    ids = unique(df.ID)
    instancevec = PMInstance[]
    for idtmp in ids
        df_id = @chain df begin
            @filter(ID == !!idtmp)
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

