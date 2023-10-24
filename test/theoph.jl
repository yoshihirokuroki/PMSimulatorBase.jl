using DataFrames
using CSV
using Tidier
using PMSimulator
include("house.jl");
theoph = DataFrame(CSV.File("exTheoph.csv"))

theoph = @chain theoph begin
    @rename(input = cmt)
    @mutate(input = ifelse(input == 1, :GUTin, :none))
end

PMSimulator.df2evs(theoph)d