from programs import velocity_transport_convergence, velocity_transport

# Problem setup.
parameters = velocity_transport_convergence.get_default_run_parameters()
parameters["verbose_output"] = False

parameters["scaling_D"] = 1.0
parameters["scaling_L"] = 1.0
parameters["scaling_R"] = 1.0
parameters["scaling_U"] = 1.0
parameters["scaling_k"] = 1.0
parameters["scaling_mu"] = 1.0
parameters["scaling_rho"] = 1.0

parameters["zero_velocity_reaction_coefficient"] = False

# Run type.
parameters["run_type"]      = 'openmp'
parameters["linear_solver"] = 'mumps'
parameters["no_threads"]    = 20

# Plot.
parameters["plot"] = True

# Clean and compile.
velocity_transport.setup(clean=False, terminal_output=True, compile=True, compile_clean=False, run_type=parameters["run_type"], verbose_output=True, compile_entry='velocity-transport_convergence')

# Run the simulations.
parameters["geometry"] = "square_analytic"
parameters["no_tests"] = 5

parameters["final_time"]      = 0.0
parameters["no_time_steps"]   = 0
parameters["test_type"]       = "ss_velocity_space"
parameters["mesh_resolution"] = 2
parameters["moving_mesh"]     = False
velocity_transport_convergence.run(1, parameters)

parameters["final_time"]      = 1.0e-3
parameters["no_time_steps"]   = 10
parameters["test_type"]       = "velocity_space"
parameters["mesh_resolution"] = 2
parameters["moving_mesh"]     = False
velocity_transport_convergence.run(2, parameters)

parameters["final_time"]      = 1.0
parameters["no_time_steps"]   = 2
parameters["test_type"]       = "velocity_time"
parameters["mesh_resolution"] = 0.05
parameters["moving_mesh"]     = False
velocity_transport_convergence.run(3, parameters)

parameters["final_time"]         = 1.0e-3
parameters["no_time_steps"]      = 10
parameters["test_type"]          = "mm_velocity_space"
parameters["mesh_resolution"]    = 2
parameters["moving_mesh"]        = True
parameters["mesh_velocity_type"] = "etienne2009"
velocity_transport_convergence.run(4, parameters)

parameters["final_time"]         = 1
parameters["no_time_steps"]      = 2
parameters["test_type"]          = "mm_velocity_time"
parameters["mesh_resolution"]    = 0.05
parameters["moving_mesh"]        = True
parameters["mesh_velocity_type"] = "etienne2009"
velocity_transport_convergence.run(5, parameters)

parameters["final_time"]         = 0.0
parameters["no_time_steps"]      = 0
parameters["test_type"]          = "ss_transport_space"
parameters["mesh_resolution"]    = 2
parameters["moving_mesh"]        = False
velocity_transport_convergence.run(6, parameters)

parameters["final_time"]      = 1.0e-3
parameters["no_time_steps"]   = 10
parameters["test_type"]       = "transport_space"
parameters["mesh_resolution"] = 2
parameters["moving_mesh"]     = False
velocity_transport_convergence.run(7, parameters)

parameters["final_time"]      = 1.0
parameters["no_time_steps"]   = 2
parameters["test_type"]       = "transport_time"
parameters["mesh_resolution"] = 0.003
parameters["moving_mesh"]     = False
velocity_transport_convergence.run(8, parameters)

parameters["final_time"]         = 1.0e-3
parameters["no_time_steps"]      = 10
parameters["test_type"]          = "mm_transport_space"
parameters["mesh_resolution"]    = 2
parameters["moving_mesh"]        = True
parameters["mesh_velocity_type"] = "etienne2009"
velocity_transport_convergence.run(9, parameters)

parameters["final_time"]         = 1
parameters["no_time_steps"]      = 2
parameters["test_type"]          = "mm_transport_time"
parameters["mesh_resolution"]    = 0.003
parameters["moving_mesh"]        = True
parameters["mesh_velocity_type"] = "etienne2009"
velocity_transport_convergence.run(10, parameters)

# Save output.
from miscellaneous import output
output.save()