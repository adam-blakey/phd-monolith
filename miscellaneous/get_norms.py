def get_norms(program, geometry, run_no):
  import pandas as pd
  import numpy as np

  flux_data = pd.read_csv(f'./output/norms_{program}_{geometry}_{run_no}.dat', sep='\t', header=[0])

  no_timesteps = flux_data.get('no_timesteps').to_numpy()
  mesh_no      = flux_data.get('mesh_no').to_numpy()
  dofs         = flux_data.get('dofs').to_numpy()
  L2_u         = flux_data.get('L2_u').to_numpy()
  L2_p         = flux_data.get('L2_p').to_numpy()
  L2_up        = flux_data.get('L2_up').to_numpy()
  E_up         = flux_data.get('DG_up').to_numpy()
  div_u        = flux_data.get('L2_div_u').to_numpy()

  L2_u_ratio  = L2_u [:-1]/L2_u [1:]
  L2_p_ratio  = L2_p [:-1]/L2_p [1:]
  L2_up_ratio = L2_up[:-1]/L2_up[1:]
  E_up_ratio  = E_up [:-1]/E_up [1:]
  div_u_ratio = div_u[:-1]/div_u[1:]

  return np.array([no_timesteps, dofs, L2_u, L2_p, L2_up, E_up, div_u]), np.array([L2_u_ratio, L2_p_ratio, L2_up_ratio, E_up_ratio, div_u_ratio])