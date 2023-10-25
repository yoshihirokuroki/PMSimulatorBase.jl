using Revise
using PMParameterized
using PMSimulator


vori = @model vori begin
    @IVs t [unit = u"hr", description = "Independent variable (time in hours)", tspan = (0.0, 100.0)] 
    D = Differential(t)
    @parameters begin
        # Tissue volumes
        Vad = 18.2, [unit = u"L", description = "Adipose tissue volume"]
        Vbo = 10.5, [unit = u"L", description = "Bone tissue volume"]
        Vbr = 1.45, [unit = u"L", description = "Brain tissue volume"]
        VguWall = 0.65, [unit = u"L", description = "Gut Wall tissue volume"]
        VguLumen = 0.35, [unit = u"L", description = "Gut Lumen tissue volume"]
        Vhe = 0.33, [unit = u"L", description = "Heart tissue volume"]
        Vki = 0.31, [unit = u"L", description = "Kidney tissue volume"]
        Vli = 1.8, [unit = u"L", description = "Liver tissue volume"]
        Vlu = 0.5, [unit = u"L", description = "Lungs tissue volume"]
        Vmu = 29.0, [unit = u"L", description = "Muscle tissue volume"]
        Vsp = 0.15, [unit = u"L", description = "Spleen tissue volume"]
        Vbl = 5.6, [unit = u"L", description = "Blood tissue volume"]
        # Tissue Blood Flows
        Qad = 0.05*6.5*60, [unit = u"L*hr^-1", description = "Adipose tissue blood flow"]
        Qbo = 0.05*6.5*60, [unit = u"L*hr^-1", description = "Bone tissue blood flow"]
        Qbr = 0.12*6.5*60, [unit = u"L*hr^-1", description = "Brain tissue blood flow"]
        Qgu = 0.15*6.5*60, [unit = u"L*hr^-1", description = "Gut tissue blood flow"] 
        Qhe = 0.04*6.5*60, [unit = u"L*hr^-1", description = "Heart tissue blood flow"]
        Qki = 0.19*6.5*60, [unit = u"L*hr^-1", description = "Kidney tissue blood flow"]
        Qmu = 0.17*6.5*60, [unit = u"L*hr^-1", description = "Muscle tissue blood flow"]
        Qsp = 0.03*6.5*60, [unit = u"L*hr^-1", description = "Spleen tissue blood flow"]
        Qha = 0.065*6.5*60, [unit = u"L*hr^-1", description = "Hepatic artery blood flow"]
        Qlu = 6.5*60, [unit = u"L*hr^-1", description = "Same as Cardiac Output"]    
        # partition coefficients estimated by Poulin and Theil method https://jpharmsci.org/article/S0022-3549(16)30889-9/fulltext
        Kpad = 9.89, [description = "Adipose:plasma"]
        Kpbo = 7.91, [description = "bone:plasma"]
        Kpbr = 7.35, [description = "brain:plasma"]
        Kpgu = 5.82, [description = "gut:plasma"]
        Kphe = 1.95, [description = "heart:plasma"]
        Kpki = 2.9, [description = "kidney:plasma"]
        Kpli = 4.66, [description = "liver:plasma"]
        Kplu = 0.83, [description = "lungs:plasma"]
        Kpmu = 2.94, [description = "muscle:plasma; optimized"]
        Kpsp = 2.96, [description = "spleen:plasma"]
        Kpre = 4.0, [description = "calculated as average of non adipose Kps"]
        BP = 1.0, [description = "blood:plasma ratio"]
        # Other parameters
        WEIGHT = 73, [unit = u"kg", description = "Body weight"]
        ka = 0.849, [unit = u"hr^-1", description = "Absorption rate constant"]
        fup = 0.42, [description = "fraction of unbound drug in plasma"]
        
        # in vitro hepatic clearance parameters http://dmd.aspetjournals.org/content/38/1/25.long
        fumic = 0.711, [description = "fraction of unbound drug in microsomes"]
        MPPGL = 30.3#, [unit = u"mg*g^-1", description = "adult mg microsomal protein per g liver"]
        VmaxH = 40, [unit = u"hr^-1", description = "adult hepatic Vmax"]#[unit = u"pmol * minute^-1 * mg^-1", description = "adult hepatic Vmax"]
        KmH = 9.3#, [unit = u"μM", description = "adult hepatic Km"]
        
        # renal clearance  https://link.springer.com/article/10.1007%2Fs40262-014-0181-y
        CL_Ki = 0.096 * WEIGHT/73, [unit = u"L*hr^-1", description = "renal clearance"]
        VenIC = 10.0, [unit = u"mg", description = "Venous blood initial drug amount"]
        Cscaler = 0.0, [unit = u"mg/L", description = "Add a constant offset to observed concentrations for testing"]
    end




    @variables begin
        (Gut_lumen(t) = 0.0), [unit = u"mg", description = "Drug in Gut Lumen"]
        (Gut(t) = 0.0), [unit = u"mg", description = "Drug in Gut"]
        (Adipose(t) = 0.0), [unit = u"mg", description = "Drug in Adipose"]
        (Brain(t) = 0.0), [unit = u"mg", description = "Drug in Brain"]
        (Heart(t) = 0.0), [unit = u"mg", description = "Drug in Heart"]
        (Kidney(t) = 0.0), [unit = u"mg", description = "Drug in Kidney"]
        (Liver(t) = 0.0), [unit = u"mg", description = "Drug in Liver"]
        (Lung(t) = 0.0), [unit = u"mg", description = "Drug in Lung"]
        (Muscle(t) = 0.0), [unit = u"mg", description = "Drug in Muscle"]
        (Spleen(t) = 0.0), [unit = u"mg", description = "Drug in Spleen"]
        (Bone(t) = 0.0), [unit = u"mg", description = "Drug in Bone"]
        (Rest(t) = 0.0), [unit = u"mg", description = "Drug in Rest of tissue"]
        (Ven(t) = VenIC), [unit = u"mg", description = "Venous drug"]
        (Art(t) = 0.0), [unit = u"mg", description = "Arterial drug"]
    end

    @constants kgtoL = 1.0, [unit = u"L*kg^-1", description = "Convert Kg to liters assuming water density is 1kg/L"]
    # additional volume derivations
    Vve = 0.705*Vbl; #venous blood
    Var = 0.295*Vbl; #arterial blood
    Vre = WEIGHT*kgtoL - (Vli+Vki+Vsp+Vhe+Vlu+Vbo+Vbr+Vmu+Vad+VguWall+Vbl); #volume of rest of the body compartment
    
    # additional blood flow derivation
    Qli = Qgu + Qsp + Qha;
    Qre = Qlu - (Qli + Qki + Qbo + Qhe + Qmu + Qad + Qbr);
    
    # intrinsic hepatic clearance calculation
    @observed CL_Li = ((VmaxH/KmH)*MPPGL*Vli*1000*60*1e-6) / fumic; #(L/hr) hepatic clearance

    @observed begin
        Cadiposes_scaled = Adipose/Vad + Cscaler;
        Cadipose = Adipose/Vad;
        Cbone = Bone/Vbo;
        Cbrain = Brain/Vbr; 
        Cheart = Heart/Vhe; 
        Ckidney = Kidney/Vki;
        Cliver = Liver/Vli; 
        Clung = Lung/Vlu; 
        Cmuscle = Muscle/Vmu;
        Cspleen = Spleen/Vsp;
        Crest = Rest/Vre;
        Carterial = Art/Var;
        Cvenous = Ven/Vve;
        CgutLumen = Gut_lumen/VguLumen;
        Cgut = Gut/VguWall;
    end

    @eq D(Gut_lumen) ~ -ka*Gut_lumen;
    @eq D(Gut) ~ ka*Gut_lumen + Qgu*(Carterial - Cgut/(Kpgu/BP)); 
    @eq D(Adipose) ~ Qad*(Carterial - Cadipose/(Kpad/BP)); 
    @eq D(Brain) ~ Qbr*(Carterial - Cbrain/(Kpbr/BP));
    @eq D(Heart) ~ Qhe*(Carterial - Cheart/(Kphe/BP));
    @eq D(Kidney) ~ Qki*(Carterial - Ckidney/(Kpki/BP)) - CL_Ki*(fup*Ckidney/(Kpki/BP));
    @eq D(Liver) ~ Qgu*(Cgut/(Kpgu/BP)) + Qsp*(Cspleen/(Kpsp/BP)) + Qha*(Carterial) - Qli*(Cliver/(Kpli/BP)) - 
      CL_Li*(fup*Cliver/(Kpli/BP)); 
    @eq D(Lung) ~ Qlu*(Cvenous - Clung/(Kplu/BP));
    @eq D(Muscle) ~ Qmu*(Carterial - Cmuscle/(Kpmu/BP));
    @eq D(Spleen) ~ Qsp*(Carterial - Cspleen/(Kpsp/BP));
    @eq D(Bone) ~ Qbo*(Carterial - Cbone/(Kpbo/BP));
    @eq D(Rest) ~ Qre*(Carterial - Crest/(Kpre/BP));
    @eq D(Ven) ~ Qad*(Cadipose/(Kpad/BP)) + Qbr*(Cbrain/(Kpbr/BP)) +
      Qhe*(Cheart/(Kphe/BP)) + Qki*(Ckidney/(Kpki/BP)) + Qli*(Cliver/(Kpli/BP)) + 
      Qmu*(Cmuscle/(Kpmu/BP)) + Qbo*(Cbone/(Kpbo/BP)) + Qre*(Crest/(Kpre/BP)) - Qlu*Cvenous;
    @eq D(Art) ~ Qlu*(Clung/(Kplu/BP) - Carterial);
end;



ev1 = PMSimulator.PMInput(time = 1.0, amt = 4.0, tinf = 0.5, input = :Ven);
ev2 = PMSimulator.PMInput(time = 10.0, amt = 0.25, input = :Ven);
ev3 = PMSimulator.PMInput(time = 0.0, amt = 0.4, input = :Ven)
evs = PMSimulator.collect_evs([ev1, ev2, ev3], vori); # Working on moving this into the solve function, should just be able to pass a vector of events

vori.tspan = (0.0, 25.0) # This is kind of hidden, working on a fix...

vori.parameters.VenIC = 4.0;
sol1 = PMParameterized.solve(vori);
sol2 = PMParameterized.solve(vori, callback = evs);

using Plots
plot(sol1.t,sol1.Ven)
plot!(sol2.t,sol2.Ven)

# Observed
plot(sol2.t, sol2.Adipose) # Venous drug concentration
vori.parameters.Cscaler = 100.0
soltmp = PMParameterized.solve(vori, callback = evs);
plot!(soltmp.t, soltmp.Cadiposes_scaled)

# vori.parameters.WEIGHT = 100.0
vori.parameters = (VenIC = 2.0, WEIGHT = 72)
sol3 = PMParameterized.solve(vori, callback=evs);
plot(sol2.t, sol2.Ven)
plot!(sol3.t,sol3.Ven)


# Internals
vori.parameters.CL_Ki._valmap
vori.parameters.CL_Ki._uvalues
vori.parameters.CL_Ki = 1.0
vori.parameters.CL_Ki._uvalues

vori.parameters.CL_Ki*3.2

