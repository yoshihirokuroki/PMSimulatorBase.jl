using Revise
using DataFrames
using CSV
using Tidier
using PMSimulator
include("house.jl");
theoph = DataFrame(CSV.File("exTheoph.csv"));

theoph = @chain theoph begin
    @rename(input = cmt)
    @mutate(input = ifelse(input == 1, :GUTin, :none))
    @mutate(tinf = 2.0)
end;

theoph_ev = PMSimulator.df2evs(theoph);

