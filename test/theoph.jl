using Revise
using DataFrames
using CSV
using Tidier
using PMSimulator
include("house.jl");
theoph = DataFrame(CSV.File("exTheoph.csv"));

theoph = @chain theoph begin
    @rename(input = cmt)
    @mutate(input = ifelse(input == 1, :GUT, :nothing))
    @mutate(tinf = 2.0)
end;

theoph_ev = PMSimulator.df2evs(theoph);
house.states.GUT = 0.0


### CREATE COPY OF MODEL FIRST?

cbs = PMSimulator.collect_evs([theoph_ev.instances[1].inputs..., theoph_ev.instances[1].updates...], house);
sol = PMParameterized.solve(house, callback = cbs);



using Plots
plot(sol.t, sol.GUT)