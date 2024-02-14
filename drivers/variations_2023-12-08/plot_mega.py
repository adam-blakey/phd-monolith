def plot(simulations, simulation_bins, parameter_values, parameter_name, parameter_safe_name, subfolder=None):
  import numpy as np

  print(f"\rPlotting simulations...", end="")
  no_bins = len(simulation_bins[0][0])

  assert(len(parameter_values) == 2)
  assert(len(simulation_bins) == 2)
  assert(len(simulation_bins[0]) == 2)

  # Setup plots.
  from plotting import setup_plots
  fig, axes = setup_plots.setup_megaplot(1, 8, 2, figsize=(8, 18))

  # Get data to plot.
  data = np.zeros((2, 2), dtype=object)
  for j in range(2):
    for i in range(2):
      data[i, j] = setup_plots.get_data(len(simulation_bins[j][i]), simulation_bins[j][i], simulations)

  # Patches for legends.
  import matplotlib.patches as mpatches
  max_no_patches = 4
  handles = []
  for i in range(max_no_patches):
    handles.append(mpatches.Patch(color=f"C{i}"))

  # AXES 1: Velocity magnitude integrals.
  for j in range(2):
    for i in range(2):
      axes[0][j].plot(parameter_values[j], data[i, j]["q50"]["velocity_magnitude_integral"], linestyle="dashed", color=f"C{i}")
      axes[0][j].fill_between(parameter_values[j], data[i, j]["q25"]["velocity_magnitude_integral"], data[i, j]["q75"]["velocity_magnitude_integral"], alpha=0.2, color=f"C{i}")
    
  axes[0][0].legend(handles=handles[0:2], labels=["any veins", "27 veins"])
  axes[0][1].legend(handles=handles[0:2], labels=["any arteries", "6 arteries"])

  # AXES 2: Slow velocity percentages.
  for j in range(2):
    axes[1][j].plot(parameter_values[j], data[0, j]["q50"]["slow_velocity_percentage_ivs"], linestyle="dashed", color="C0")
    axes[1][j].plot(parameter_values[j], data[0, j]["q50"]["slow_velocity_percentage_everywhere"], linestyle="dashed", color="C1")
    axes[1][j].plot(parameter_values[j], data[0, j]["q50"]["slow_velocity_percentage_dellschaft"], linestyle="dashed", color="C2")
    axes[1][j].plot(parameter_values[j], data[0, j]["q50"]["slow_velocity_percentage_nominal_everywhere"], linestyle="dashed", color="C3")
    axes[1][j].fill_between(parameter_values[j], data[0, j]["q25"]["slow_velocity_percentage_ivs"], data[0, j]["q75"]["slow_velocity_percentage_ivs"], alpha=0.2, color="C0")
    axes[1][j].fill_between(parameter_values[j], data[0, j]["q25"]["slow_velocity_percentage_everywhere"], data[0, j]["q75"]["slow_velocity_percentage_everywhere"], alpha=0.2, color="C1")
    axes[1][j].fill_between(parameter_values[j], data[0, j]["q25"]["slow_velocity_percentage_dellschaft"], data[0, j]["q75"]["slow_velocity_percentage_dellschaft"], alpha=0.2, color="C2")
    axes[1][j].fill_between(parameter_values[j], data[0, j]["q25"]["slow_velocity_percentage_nominal_everywhere"], data[0, j]["q75"]["slow_velocity_percentage_nominal_everywhere"], alpha=0.2, color="C3")
    axes[1][j].legend(handles=handles[0:4], labels=["IVS", "everywhere", "Dellschaft", "nominal everywhere"])

  # AXES 3: Velocity flux through different veins.
  for j in range(2):
    axes[2][j].plot(parameter_values[j], data[0, j]["q50"]["velocity_percentage_basal_plate"], linestyle="dashed", color="C0")
    axes[2][j].plot(parameter_values[j], data[0, j]["q50"]["velocity_percentage_septal_wall"], linestyle="dashed", color="C1")
    axes[2][j].plot(parameter_values[j], data[0, j]["q50"]["velocity_percentage_marginal_sinus"], linestyle="dashed", color="C2")
    axes[2][j].fill_between(parameter_values[j], data[0, j]["q25"]["velocity_percentage_basal_plate"], data[0, j]["q75"]["velocity_percentage_basal_plate"], alpha=0.2, color="C0")
    axes[2][j].fill_between(parameter_values[j], data[0, j]["q25"]["velocity_percentage_septal_wall"], data[0, j]["q75"]["velocity_percentage_septal_wall"], alpha=0.2, color="C1")
    axes[2][j].fill_between(parameter_values[j], data[0, j]["q25"]["velocity_percentage_marginal_sinus"], data[0, j]["q75"]["velocity_percentage_marginal_sinus"], alpha=0.2, color="C2")
    axes[2][j].legend(handles=handles[0:3], labels=["basal plate", "septal wall", "marginal sinus"])

  # AXES 4: Cross-flux velocity.
  for j in range(2):
    for i in range(2):
      axes[3][j].plot(parameter_values[j], data[i, j]["q50"]["velocity_cross_flow_flux"], linestyle="dashed", color=f"C{i}")
      axes[3][j].fill_between(parameter_values[j], data[i, j]["q25"]["velocity_cross_flow_flux"], data[i, j]["q75"]["velocity_cross_flow_flux"], alpha=0.2, color=f"C{i}")
  axes[3][0].legend(handles=handles[0:2], labels=["any veins", "27 veins"])
  axes[3][1].legend(handles=handles[0:2], labels=["any arteries", "6 arteries"])

  # AXES 5: Transport reaction integral.
  for j in range(2):
    for i in range(2):
      axes[4][j].plot(parameter_values[j], data[i, j]["q50"]["transport_reaction_integral"], linestyle="dashed", color=f"C{i}")
      axes[4][j].fill_between(parameter_values[j], data[i, j]["q25"]["transport_reaction_integral"], data[i, j]["q75"]["transport_reaction_integral"], alpha=0.2, color=f"C{i}")
  axes[4][0].legend(handles=handles[0:2], labels=["any veins", "27 veins"])
  axes[4][1].legend(handles=handles[0:2], labels=["any arteries", "6 arteries"])

  # AXES 6: Concentration flux through different veins.
  for j in range(2):
    axes[5][j].plot(parameter_values[j], data[0, j]["q50"]["transport_percentage_basal_plate"], linestyle="dashed", color="C0")
    axes[5][j].plot(parameter_values[j], data[0, j]["q50"]["transport_percentage_septal_wall"], linestyle="dashed", color="C1")
    axes[5][j].plot(parameter_values[j], data[0, j]["q50"]["transport_percentage_marginal_sinus"], linestyle="dashed", color="C2")
    axes[5][j].fill_between(parameter_values[j], data[0, j]["q25"]["transport_percentage_basal_plate"], data[0, j]["q75"]["transport_percentage_basal_plate"], alpha=0.2, color="C0")
    axes[5][j].fill_between(parameter_values[j], data[0, j]["q25"]["transport_percentage_septal_wall"], data[0, j]["q75"]["transport_percentage_septal_wall"], alpha=0.2, color="C1")
    axes[5][j].fill_between(parameter_values[j], data[0, j]["q25"]["transport_percentage_marginal_sinus"], data[0, j]["q75"]["transport_percentage_marginal_sinus"], alpha=0.2, color="C2")
    axes[5][j].legend(handles=handles[0:3], labels=["basal plate", "septal wall", "marginal sinus"])

  # AXES 7: Kinetic energy flux difference.
  for j in range(2):
    for i in range(2):
      axes[6][j].plot(parameter_values[j], data[i, j]["q50"]["kinetic_energy_flux"], linestyle="dashed", color=f"C{i}")
      axes[6][j].fill_between(parameter_values[j], data[i, j]["q25"]["kinetic_energy_flux"], data[i, j]["q75"]["kinetic_energy_flux"], alpha=0.2, color=f"C{i}")
  axes[6][0].legend(handles=handles[0:2], labels=["any veins", "27 veins"])
  axes[6][1].legend(handles=handles[0:2], labels=["any arteries", "6 arteries"])

  # AXES 8: Total energy flux difference.
  for j in range(2):
    for i in range(2):
      axes[7][j].plot(parameter_values[j], data[i, j]["q50"]["total_energy_flux"], linestyle="dashed", color=f"C{i}")
      axes[7][j].fill_between(parameter_values[j], data[i, j]["q25"]["total_energy_flux"], data[i, j]["q75"]["total_energy_flux"], alpha=0.2, color=f"C{i}")
  axes[7][0].legend(handles=handles[0:2], labels=["any veins", "27 veins"])
  axes[7][1].legend(handles=handles[0:2], labels=["any arteries", "6 arteries"])

  # Style plots.
  setup_plots.style(fig, axes[0][0], None, r"$\bar{v}$", y_scilimits=[-3, -3] , y_bottom=0, y_top=1e-2, integer_ticks=True)
  setup_plots.style(fig, axes[1][0], None, r"$v_\text{slow}(V_\text{threshold})$", y_scilimits=None , y_top=102, integer_ticks=True)
  setup_plots.style(fig, axes[2][0], None, r"$\frac{v_\text{flux}(S)}{v_\text{flux}(\Gamma_\text{in})}$", y_scilimits=None , y_top=102, integer_ticks=True)
  setup_plots.style(fig, axes[3][0], None, r"$v_\text{cross}$", y_scilimits=[-3, -3] , y_bottom=0, y_top=2e-2, integer_ticks=True)
  setup_plots.style(fig, axes[4][0], None, r"$\bar{c}$", y_scilimits=[-3, -3], y_bottom=0, y_top=2e-3, integer_ticks=True)
  setup_plots.style(fig, axes[5][0], None, r"$c_\text{flux}(\Gamma_\text{in}) - c_\text{flux}(\Gamma_\text{out})$", y_scilimits=None , y_top=102, integer_ticks=True, y_labelpad=15)
  setup_plots.style(fig, axes[6][0], None, r"$E_\text{kinetic}(\Gamma_\text{in}) - E_\text{kinetic}(\Gamma_\text{out})$", y_scilimits=[-3, -3], y_bottom=0, y_top=2e-3, integer_ticks=True, y_labelpad=5)
  setup_plots.style(fig, axes[7][0], parameter_name[0], r"$E_\text{total}(\Gamma_\text{in}) - E_\text{total}(\Gamma_\text{out})$", y_scilimits=[4, 4], y_bottom=0, y_top=1e5, integer_ticks=True, y_labelpad=15)

  setup_plots.style(fig, axes[0][1], None, None, y_scilimits=[-3, -3], y_bottom=0, y_top=1e-2, integer_ticks=True)
  setup_plots.style(fig, axes[1][1], None, None, y_scilimits=None , y_top=102, integer_ticks=True)
  setup_plots.style(fig, axes[2][1], None, None, y_scilimits=None , y_top=102, integer_ticks=True)
  setup_plots.style(fig, axes[3][1], None, None, y_scilimits=[-3, -3], y_bottom=0, y_top=2e-2, integer_ticks=True)
  setup_plots.style(fig, axes[4][1], None, None, y_scilimits=[-3, -3], y_bottom=0, y_top=2e-3, integer_ticks=True)
  setup_plots.style(fig, axes[5][1], None, None, y_scilimits=None , y_top=102, integer_ticks=True)
  setup_plots.style(fig, axes[6][1], None, None, y_scilimits=[-3, -3], y_bottom=0, y_top=2e-3, integer_ticks=True)
  setup_plots.style(fig, axes[7][1], parameter_name[1], None, y_scilimits=[4, 4], y_bottom=0, y_top=1e5, integer_ticks=True)

  # Decide where to save plots.
  if subfolder == None:
    images_folder = "images"
  else:
    images_folder = f"images/{subfolder}"

  # Save.
  fig.savefig(f"{images_folder}/mega_{parameter_safe_name[0]}_{parameter_safe_name[1]}.png", dpi=300)

  # Done.
  print(f"\rPlotting simulations... Done.", end="\r\n")