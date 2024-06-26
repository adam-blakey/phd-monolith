####################
# SIMULATION SETUP #
####################
from programs import velocity_transport

parameters = velocity_transport.get_default_run_parameters()

# Problem type.
parameters["velocity_model"] = "nsb"

# Geometry measurements.
parameters["central_cavity_width"]      = 0.25
parameters["central_cavity_height"]     = 0.50
parameters["central_cavity_transition"] = 0.12
parameters["pipe_transition"]           = 0.03
parameters["vessel_fillet_radius"]      = 0.01
parameters["artery_width"]              = 0.06
parameters["artery_width_sm"]           = 0.0125
parameters["no_placentones"]            = 6
parameters["geometry"]                  = "placenta"

# Problem parameters.
parameters["scaling_L"]   = 0.04     # m
parameters["scaling_U"]   = 0.35     # m/s
parameters["scaling_k"]   = 1e-8     # m^2
parameters["scaling_mu"]  = 4e-3     # Pa s
parameters["scaling_rho"] = 1e3      # kg/m^3
parameters["scaling_D"]   = 1.667e-9 # m^2/s
parameters["scaling_R"]   = 1.667e-2 # m^2/s

# Output.
parameters["terminal_output"] = True
parameters["verbose_output"]  = False
parameters["plot"]            = False

# Mesh resolution.
parameters["mesh_resolution"] = 0.02

# Simulation.
parameters["compute_permeability"       ] = True
parameters["compute_transport"          ] = True
parameters["compute_uptake"             ] = True
parameters["compute_velocity"           ] = True
parameters["compute_velocity_average"   ] = True
parameters["compute_velocity_sample"    ] = True
parameters["compute_mri"                ] = True
parameters["run_mesh_generation"        ] = True
parameters["run_aptofem_simulation"     ] = True
parameters["run_set_aptofem_parameters" ] = True
parameters["oscillation_detection"      ] = True
parameters["generate_outline_mesh"      ] = True

# File handling.
parameters["compress_output"] = False
parameters["clean_files"][0]  = False # Output VTKs.
parameters["clean_files"][1]  = False # Output restarts.
parameters["clean_files"][2]  = False # Output data files.
parameters["clean_files"][3]  = False # Output log files.
parameters["clean_files"][4]  = False # Mesh mshs.
parameters["clean_files"][5]  = False # Mesh VTKs.
parameters["clean_files"][6]  = False # Images.

# Reruns.
parameters["error_on_fail"           ] = True
parameters["rerun_with_reynold_steps"] = False

# Run type.
parameters["run_type"]      = 'openmp'
parameters["linear_solver"] = 'mumps'
parameters["no_threads"]    = 20

# Turn off some veins.
parameters["basal_plate_vessels"] = [[0, 1, 1], [1, 1, 0], [1, 1, 0], [0, 1, 1], [1, 1, 0], [0, 1, 1]]

##################
# SIMULATION RUN #
##################
# Clean and compile.
velocity_transport.setup(clean=True, terminal_output=True, compile=True, compile_clean=False, run_type=parameters["run_type"], verbose_output=True)

# Run simulations.
velocity_transport.run(1, parameters)

# Save output.
from miscellaneous import output
output.save()