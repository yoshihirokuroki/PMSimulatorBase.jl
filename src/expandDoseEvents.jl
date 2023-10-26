"""
    expandDoseEvents!(idf::AbstractDataFrame)

Expand events in individualized input dataframe

# Arguments:

- `idf`: Individualized input dataset.
"""
function expandDoseEvents!(idf::AbstractDataFrame)
        
    # do conversions of column names in input data
    if "AMT" in names(idf); rename!(idf, :AMT => :amt); end
    if "TIME" in names(idf); rename!(idf, :TIME => :time); end
    if "CMT" in names(idf); rename!(idf, :CMT => :cmt); end
    if "EVID" in names(idf); rename!(idf, :EVID => :evid); end
    if "RATE" in names(idf); rename!(idf, :RATE => :rate); end
    if "II" in names(idf); rename!(idf, :II => :ii); end
    if "ADDL" in names(idf); rename!(idf, :ADDL => :addl); end
    if "id" in names(idf); rename!(idf, :id => :ID); end

    if !("cmt" in names(idf)); idf[:,:cmt] .= 1; end
    if !("ii" in names(idf)); idf[:,:ii] .= 0.0; end
    if !("addl" in names(idf)); idf[:,:addl] .= 0; end
    if !("rate" in names(idf)); idf[:,:rate] .= 0.0; end
    # if !("F" in names(idf)); idf[:,:F] .= 1.0; end
    # if !("alag" in names(idf)); idf[:,:alag] .= 0.0; end
    # if !("ss" in names(idf)); idf[:,:ss] .= 0.0; end

    if ("F" in names(df)); @warn "F not currently supported"; end
    if ("alag" in names(df)); @warn "alag not currently supported"; end
    if ("ss" in names(df)); @warn "ss not currently supported"; end

    idf_dose = idf[idf.evid .== 1,:] 
    idf_dose_no_ii = idf_dose[idf_dose.ii .== 0.0,:] 
    idf_dose_ii = idf_dose[idf_dose.ii .> 0.0,:] 

    idf_all = idf_dose_no_ii

    for i in 1:nrow(idf_dose_ii)
        ii = idf_dose_ii[i, :ii]
        addl = idf_dose_ii[i, :addl]

        idf_dose_ii_2 = idf_dose_ii[i, :] |> DataFrame
        idf_dose_ii_3 = repeat(idf_dose_ii_2, addl + 1)
        times = idf_dose_ii_3[:,:time] .+ cumsum(idf_dose_ii_3[:,:ii]) .- ii
        idf_dose_ii_3[:,:time] = times
        
        idf_dose_ii_4 = idf_dose_ii_3
        idf_dose_ii_4.ii .= 0.0
        idf_dose_ii_4.addl .= 0

        idf_all = append!(idf_all, idf_dose_ii_4)
    end

    if any(idf[:,:evid] .== 0)
        idf_obs = idf[idf.evid .== 0,:]
        idf_all2 = sort(vcat(idf_all, idf_obs), :time) 
    else
        idf_all2 = sort(idf_all, :time) 
    end

    return(idf_all2)
end