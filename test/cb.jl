include("house.jl");
using ModelingToolkit
@parameters t
@variables x(t)
D = Differential(t)

eqs = [D(x) + 0 ~ -0.1*x]
@named sys = ODESystem(eqs)

function condition(u, t, integrator) # Event when condition(u,t,integrator) == 0
    # integrator.iter % 3 ==0
    t<5
end

function affect!(integrator)
    # println(integrator.dt)
integrator.u[1] += 0.5*integrator.dt
    # get_du(integrator)[1] += 2.0
    # println(get_du(integrator))
    return integrator
end


cb = DiscreteCallback(condition, affect!, save_positions = (false, false))
prob = ODEProblem(sys,[x => 0.0], (0.0, 24.0))
integrator = init(prob)
using DifferentialEquations
sol = DifferentialEquations.solve(prob, callback=cb)#,tstops=0:0.1:24.0);
plot(0:0.1:24, sol(0:0.1:24)[1,:])