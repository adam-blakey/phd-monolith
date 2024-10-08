class class_run_data:
  def __init__(self, sim_no, subfolder):
    self.sim_no = sim_no

    self.read_data(subfolder)

  def read_data(self, subfolder=None):
    from miscellaneous import get_transport_reaction_integral, get_velocity_magnitude, get_run_data, parameters_io, get_flux

    self.parameters = parameters_io.load_parameters("velocity-transport", "placenta", self.sim_no, subfolder)

    U   = self.parameters["scaling_U"]
    #C   = 7.3 # mol/m^3 [Serov, 2015]
    C   = 1.0 # If C is a concentration.
    L   = self.parameters["scaling_L"]
    R   = self.parameters["scaling_R"]
    rho = self.parameters["scaling_rho"]
    mu  = self.parameters["scaling_mu"]

    ## GATHER DATA ##
    vmi  = get_velocity_magnitude         .get_velocity_magnitude_integral("velocity-transport", "placenta", self.sim_no                                   , subfolder)
    tri  = get_transport_reaction_integral.get_transport_reaction_integral("velocity-transport", "placenta", self.sim_no                                   , subfolder)
    svp  = get_velocity_magnitude         .get_slow_velocity_percentage   ("velocity-transport", "placenta", self.sim_no                                   , subfolder)
    flux = get_flux                       .get_fluxes                     ("velocity-transport", "placenta", self.sim_no, self.parameters["no_placentones"], subfolder)
    one  = get_velocity_magnitude         .get_one_integral               ("velocity-transport", "placenta", self.sim_no                                   , subfolder)
    
    self.run_data = get_run_data.get_run_data("velocity-transport", "placenta", self.sim_no, 0, subfolder)

    ## QUANTITIES WE'LL DIRECTLY USE ##
    # Velocity magnitude integral.
    self.velocity_magnitude_integral_ivs        = U*vmi[0]/one[0]
    self.velocity_magnitude_integral_everywhere = U*vmi[1]/one[1]

    # Slow velocity percentage.
    self.slow_velocity_percentage_ivs                = svp[0]/one[0]
    self.slow_velocity_percentage_everywhere         = svp[1]/one[1]
    self.slow_velocity_percentage_dellschaft         = svp[2]/one[1]
    self.fast_velocity_percentage_dellschaft         = svp[3]/one[1]
    self.slow_velocity_percentage_nominal_ivs        = svp[4]/one[0]
    self.slow_velocity_percentage_nominal_everywhere = svp[5]/one[1]

    # Transport reaction integral.
    self.transport_reaction_integral = tri/one[1] # <-- Already multiplied by the reaction coefficient.

    # Kinetic energy flux.
    ke_in  = 0.0
    for i in range(self.parameters["no_placentones"]):
      if self.parameters["basal_plate_vessels"][i][1] == 1:
        ke_in -= flux['ke_inlet_fluxes'][i]#/flux['one_inlet'][i]
    ke_out = 0.0
    for i in range(self.parameters["no_placentones"]):
      if self.parameters["basal_plate_vessels"][i][0] == 1:
        ke_out += flux['ke_bp_outlet_fluxes'][i][0]#/flux['one_bp_outlet'][i][0]
      if self.parameters["basal_plate_vessels"][i][2] == 1:
        ke_out += flux['ke_bp_outlet_fluxes'][i][1]#/flux['one_bp_outlet'][i][1]
    for i in range(self.parameters["no_placentones"]-1):
      if self.parameters["septal_veins"][i][0] == 1:
        ke_out += flux['ke_sw_outlet_fluxes'][i][0]#/flux['one_sw_outlet'][i][0]
      if self.parameters["septal_veins"][i][1] == 1:
        ke_out += flux['ke_sw_outlet_fluxes'][i][1]#/flux['one_sw_outlet'][i][1]
      if self.parameters["septal_veins"][i][2] == 1:
        ke_out += flux['ke_sw_outlet_fluxes'][i][2]#/flux['one_sw_outlet'][i][2]
    for i in range(2):
      ke_out += flux['ke_ms_outlet_fluxes'][i]#/flux['one_ms_outlet'][i]
    # self.kinetic_energy_flux = rho*U**3*(ke_in - ke_out)
    self.kinetic_energy_flux = (rho*U**3*ke_in - rho*U**3*ke_out)/(rho*U**3*ke_in)
    # self.kinetic_energy_flux = (ke_in - ke_out)/(ke_in)

    # Total energy flux (pressure energy + kinetic energy).
    pe_in  = 0.0
    for i in range(self.parameters["no_placentones"]):
      if self.parameters["basal_plate_vessels"][i][1] == 1:
        pe_in -= flux['pe_inlet_fluxes'][i]#/flux['one_inlet'][i]
    pe_out = 0.0
    for i in range(self.parameters["no_placentones"]):
      if self.parameters["basal_plate_vessels"][i][0] == 1:
        pe_out += flux['pe_bp_outlet_fluxes'][i][0]#/flux['one_bp_outlet'][i][0]
      if self.parameters["basal_plate_vessels"][i][2] == 1:
        pe_out += flux['pe_bp_outlet_fluxes'][i][1]#/flux['one_bp_outlet'][i][1]
    for i in range(self.parameters["no_placentones"]-1):
      if self.parameters["septal_veins"][i][0] == 1:
        pe_out += flux['pe_sw_outlet_fluxes'][i][0]#/flux['one_sw_outlet'][i][0]
      if self.parameters["septal_veins"][i][1] == 1:
        pe_out += flux['pe_sw_outlet_fluxes'][i][1]#/flux['one_sw_outlet'][i][1]
      if self.parameters["septal_veins"][i][2] == 1:
        pe_out += flux['pe_sw_outlet_fluxes'][i][2]#/flux['one_sw_outlet'][i][2]
    for i in range(2):
      pe_out += flux['pe_ms_outlet_fluxes'][i]#/flux['one_ms_outlet'][i]
    # self.total_energy_flux = self.kinetic_energy_flux + (mu*U/L)*U*(pe_in - pe_out)
    # self.total_energy_flux = (rho*U**3*ke_in + (mu*U/L)*U*pe_in - rho*U**3*ke_out - (mu*U/L)*U*pe_out)/(rho*U**3*ke_in + (mu*U/L)*U*pe_in)
    # self.total_energy_flux = (ke_in + mu/(L*U*rho)*pe_in - ke_out - mu/(L*U*rho)*pe_out)/(ke_in + mu/(L*U*rho)*pe_in)
    
    #self.pressure_energy_flux = (mu*U/L*U*pe_in - mu*U/L*U*pe_out)/(mu*U/L*U*pe_in) 
    self.pressure_energy_flux = (pe_in - pe_out)/(pe_in) 
    
    self.total_energy_flux = (rho*U**3*ke_in + mu*U/L*U*pe_in - rho*U**3*ke_out - mu*U/L*U*pe_out)/(rho*U**3*ke_in + mu*U/L*U*pe_in)

    # Velocity cross flow flux.
    self.velocity_cross_flow_flux     = flux['velocity_cross_flow_fluxes']
    self.abs_velocity_cross_flow_flux = 0
    for i in range(self.parameters["no_placentones"]-1):
      self.velocity_cross_flow_flux[i] *= U
      self.abs_velocity_cross_flow_flux += abs(self.velocity_cross_flow_flux[i])

    # Transport flux.
    transport_in  = 0.0
    for i in range(self.parameters["no_placentones"]):
      if self.parameters["basal_plate_vessels"][i][1] == 1:
        transport_in -= flux['transport_inlet_fluxes'][i]/flux['one_inlet'][i]
    transport_out = 0.0
    for i in range(self.parameters["no_placentones"]):
      if self.parameters["basal_plate_vessels"][i][0] == 1:
        transport_out += flux['transport_bp_outlet_fluxes'][i][0]/flux['one_bp_outlet'][i][0]
      if self.parameters["basal_plate_vessels"][i][2] == 1:
        transport_out += flux['transport_bp_outlet_fluxes'][i][1]/flux['one_bp_outlet'][i][1]
    for i in range(self.parameters["no_placentones"]-1):
      if self.parameters["septal_veins"][i][0] == 1:
        transport_out += flux['transport_sw_outlet_fluxes'][i][0]/flux['one_sw_outlet'][i][0]
      if self.parameters["septal_veins"][i][1] == 1:
        transport_out += flux['transport_sw_outlet_fluxes'][i][1]/flux['one_sw_outlet'][i][1]
      if self.parameters["septal_veins"][i][2] == 1:
        transport_out += flux['transport_sw_outlet_fluxes'][i][2]/flux['one_sw_outlet'][i][2]
    for i in range(2):
      transport_out += flux['transport_ms_outlet_fluxes'][i]/flux['one_ms_outlet'][i]
    self.transport_flux = U * (transport_in - transport_out)

    # Percentage of velocity leaving through each vein.
    velocity_in = 0.0
    for i in range(self.parameters["no_placentones"]):
      if self.parameters["basal_plate_vessels"][i][1] == 1:
        velocity_in -= flux['velocity_inlet_fluxes'][i]
    velocity_out_bp = 0.0
    for i in range(self.parameters["no_placentones"]):
      if self.parameters["basal_plate_vessels"][i][0] == 1:
        velocity_out_bp += flux['velocity_bp_outlet_fluxes'][i][0]
      if self.parameters["basal_plate_vessels"][i][2] == 1:
        velocity_out_bp += flux['velocity_bp_outlet_fluxes'][i][1]
    self.velocity_percentage_basal_plate    = 100*velocity_out_bp/velocity_in
    velocity_out_sw = 0.0
    for i in range(self.parameters["no_placentones"]-1):
      if self.parameters["septal_veins"][i][0] == 1:
        velocity_out_sw += flux['velocity_sw_outlet_fluxes'][i][0]
      if self.parameters["septal_veins"][i][1] == 1:
        velocity_out_sw += flux['velocity_sw_outlet_fluxes'][i][1]
      if self.parameters["septal_veins"][i][2] == 1:
        velocity_out_sw += flux['velocity_sw_outlet_fluxes'][i][2]
    self.velocity_percentage_septal_wall    = 100*velocity_out_sw/velocity_in
    velocity_out_ms = 0.0
    for i in range(2):
      velocity_out_ms += flux['velocity_ms_outlet_fluxes'][i]
    self.velocity_percentage_marginal_sinus = 100*velocity_out_ms/velocity_in

    # Percentage of transported nutrient leaving through each vein.
    transport_in = 0.0
    for i in range(self.parameters["no_placentones"]):
      if self.parameters["basal_plate_vessels"][i][1] == 1:
        transport_in -= flux['transport_inlet_fluxes'][i]
    transport_out_bp = 0.0
    for i in range(self.parameters["no_placentones"]):
      if self.parameters["basal_plate_vessels"][i][0] == 1:
        transport_out_bp += flux['transport_bp_outlet_fluxes'][i][0]
      if self.parameters["basal_plate_vessels"][i][2] == 1:
        transport_out_bp += flux['transport_bp_outlet_fluxes'][i][1]
    self.transport_percentage_basal_plate    = 100*transport_out_bp/transport_in
    transport_out_sw = 0.0
    for i in range(self.parameters["no_placentones"]-1):
      if self.parameters["septal_veins"][i][0] == 1:
        transport_out_sw += flux['transport_sw_outlet_fluxes'][i][0]
      if self.parameters["septal_veins"][i][1] == 1:
        transport_out_sw += flux['transport_sw_outlet_fluxes'][i][1]
      if self.parameters["septal_veins"][i][2] == 1:
        transport_out_sw += flux['transport_sw_outlet_fluxes'][i][2]
    self.transport_percentage_septal_wall    = 100*transport_out_sw/transport_in
    transport_out_ms = 0.0
    for i in range(2):
      transport_out_ms += flux['transport_ms_outlet_fluxes'][i]
    self.transport_percentage_marginal_sinus = 100*transport_out_ms/transport_in


    # print("\n")
    # print (f"Scaling U:                   {U}"                                          )
    # print (f"Average velocity IVS:        {self.average_velocity_ivs}"                  )
    # print (f"Average velocity everywhere: {self.average_velocity_everywhere}"           )
    # print (f"VMI IVS:                     {self.velocity_magnitude_integral_ivs}"       )
    # print (f"VMI everywhere:              {self.velocity_magnitude_integral_everywhere}")
    # print (f"SVP IVS:                     {self.slow_velocity_percentage_ivs}"          )
    # print (f"SVP everywhere:              {self.slow_velocity_percentage_everywhere}"   )
    # print (f"SVP Dellschaft:              {self.slow_velocity_percentage_dellschaft}"   )
    # print (f"FVP Dellschaft:              {self.fast_velocity_percentage_dellschaft}"   )
    # print (f"TRI:                         {self.transport_reaction_integral}"           )
    # print (f"KE flux:                     {self.kinetic_energy_flux}"                   )
    # print (f"TE flux:                     {self.total_energy_flux}"                     )
    # print (f"VCF:                         {self.abs_velocity_cross_flow_flux}"          )
    # print (f"TF:                          {self.transport_flux}"                        )
    # print (                                                                             )
    # exit()
    
  def get_file_contents(self, name, extension="dat"):
    file = open(f"./output/{name}_{self.sim_no}.{extension}", "r")
    lines = file.readlines()
    file.close()
    return lines
  
  def get_no_veins(self):
    import copy, numpy as np

    # Calculate number of veins.
    basal_plate_veins = copy.deepcopy(self.parameters["basal_plate_vessels"])
    for j in range(0, self.parameters["no_placentones"]):
      del basal_plate_veins[j][1]
    septal_wall_veins = self.parameters["septal_veins"]

    no_veins = int(np.count_nonzero(basal_plate_veins) + np.count_nonzero(septal_wall_veins))

    return no_veins
  
  def get_no_arteries(self):
    import copy, numpy as np
    
    # Calculate number of arteries.
    basal_plate_arteries = copy.deepcopy(self.parameters["basal_plate_vessels"])
    for j in range(0, self.parameters["no_placentones"]):
      del basal_plate_arteries[j][2]
      del basal_plate_arteries[j][0]

    no_arteries = int(np.count_nonzero(basal_plate_arteries))

    return no_arteries
  
def import_simulations(max_run_no, subfolder=None):
  simulations = []
  for run_no in range(1, max_run_no+1):
    print(f"\rImporting simulation {run_no}/{max_run_no}...", end="")
    simulations.append(class_run_data(run_no, subfolder))
  print(f"\rImporting simulation {max_run_no}/{max_run_no}... Done.", end="\r\n")

  return simulations