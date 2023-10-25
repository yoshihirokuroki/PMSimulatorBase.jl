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

# Need to move check for input in mdl from collect_evs to df2evs so we still get errors in the collect if we define an event that doesn't work. Build events slot into mdl?

### CREATE COPY OF MODEL FIRST?

### Make sure updateParamOrState checks for infusion vs. bolus
cbs = PMSimulator.collect_evs([theoph_ev.instances[1].inputs..., theoph_ev.instances[1].updates...], house);
sol = PMParameterized.solve(house, callback = cbs);



using Plots
plot(sol.t, sol.GUT)