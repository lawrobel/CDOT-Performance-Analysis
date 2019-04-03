proc power;
   twosamplesurvival 
      test=logrank
      GROUPSURVIVAL = "experimental" | "control"
      HAZARDRATIO= 1.12  /* 11% reduction in mean lifespan for hamsters with reversed LD periods */
      power = .
      alpha = 0.05
      npergroup = 20;
run;