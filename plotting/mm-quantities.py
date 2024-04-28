import numpy as np
import matplotlib as mpl
mpl.rcParams['figure.dpi'] = 600
plt = mpl.pyplot

# From data on simulation that finished 2024-04-26.
one    = np.array([3.42372, 3.42185, 3.41812, 3.41254, 3.40516, 3.39600, 3.38513, 3.37259, 3.35846, 3.34281, 3.32572, 3.30729, 3.28760, 3.26677, 3.24489, 3.22207, 3.19843, 3.17407, 3.14912, 3.12367, 3.09786, 3.07179, 3.04558, 3.01932, 2.99314, 2.96714, 2.94141, 2.91606, 2.89117, 2.86684, 2.84315, 2.82018, 2.79801, 2.77670, 2.75632, 2.73694, 2.71861, 2.70138, 2.68531, 2.67042, 2.65677, 2.64439, 2.63331, 2.62356, 2.61516, 2.60813, 2.60248, 2.59824, 2.59540, 2.59398, 2.59398, 2.59540, 2.59823, 2.60248, 2.60811, 2.61514, 2.62352, 2.63326, 2.64432, 2.65667, 2.67028, 2.68512, 2.70115, 2.71832, 2.73659, 2.75590, 2.77620, 2.79742, 2.81950, 2.84237, 2.86596, 2.89018, 2.91495, 2.94019, 2.96579, 2.99167, 3.01772, 3.04385, 3.06994, 3.09588, 3.12157, 3.14689, 3.17173, 3.19598, 3.21952, 3.24223, 3.26402, 3.28477, 3.30438, 3.32274, 3.33977, 3.35537, 3.36946, 3.38196, 3.39281, 3.40195, 3.40932, 3.41488, 3.41861, 3.42048, 3.42048])
speed  = 0.35*np.array([0.282356E-001, 0.282735E-001, 0.283046E-001, 0.283286E-001, 0.283453E-001, 0.283546E-001, 0.283562E-001, 0.283501E-001, 0.283362E-001, 0.283144E-001, 0.282848E-001, 0.282475E-001, 0.282025E-001, 0.281501E-001, 0.280905E-001, 0.280239E-001, 0.279507E-001, 0.278712E-001, 0.277858E-001, 0.276948E-001, 0.275989E-001, 0.274984E-001, 0.273939E-001, 0.272858E-001, 0.271748E-001, 0.270613E-001, 0.269459E-001, 0.268293E-001, 0.267118E-001, 0.265941E-001, 0.264767E-001, 0.263601E-001, 0.262449E-001, 0.261315E-001, 0.260204E-001, 0.259120E-001, 0.258068E-001, 0.257052E-001, 0.256075E-001, 0.255141E-001, 0.254253E-001, 0.253415E-001, 0.252629E-001, 0.251897E-001, 0.251222E-001, 0.250606E-001, 0.250050E-001, 0.249556E-001, 0.249125E-001, 0.248759E-001, 0.248457E-001, 0.248221E-001, 0.248050E-001, 0.247944E-001, 0.247904E-001, 0.247928E-001, 0.248016E-001, 0.248168E-001, 0.248381E-001, 0.248655E-001, 0.248990E-001, 0.249382E-001, 0.249832E-001, 0.250336E-001, 0.250894E-001, 0.251503E-001, 0.252161E-001, 0.252866E-001, 0.253616E-001, 0.254408E-001, 0.255239E-001, 0.256107E-001, 0.257008E-001, 0.257941E-001, 0.258902E-001, 0.259887E-001, 0.260895E-001, 0.261920E-001, 0.262961E-001, 0.264013E-001, 0.265073E-001, 0.266138E-001, 0.267203E-001, 0.268265E-001, 0.269321E-001, 0.270366E-001, 0.271397E-001, 0.272410E-001, 0.273401E-001, 0.274366E-001, 0.275302E-001, 0.276204E-001, 0.277070E-001, 0.277894E-001, 0.278674E-001, 0.279406E-001, 0.280087E-001, 0.280712E-001, 0.281281E-001, 0.281788E-001, 0.282232E-001])/one
uptake = np.array([0.353378E-002, 0.352889E-002, 0.351957E-002, 0.350630E-002, 0.348952E-002, 0.346960E-002, 0.344687E-002, 0.342163E-002, 0.339415E-002, 0.336469E-002, 0.333351E-002, 0.330086E-002, 0.326699E-002, 0.323214E-002, 0.319656E-002, 0.316047E-002, 0.312410E-002, 0.308768E-002, 0.305140E-002, 0.301548E-002, 0.298009E-002, 0.294543E-002, 0.291167E-002, 0.287896E-002, 0.284747E-002, 0.281733E-002, 0.278868E-002, 0.276163E-002, 0.273631E-002, 0.271280E-002, 0.269119E-002, 0.267155E-002, 0.265396E-002, 0.263844E-002, 0.262505E-002, 0.261380E-002, 0.260472E-002, 0.259781E-002, 0.259306E-002, 0.259047E-002, 0.259002E-002, 0.259168E-002, 0.259544E-002, 0.260127E-002, 0.260912E-002, 0.261898E-002, 0.263081E-002, 0.264458E-002, 0.266026E-002, 0.267781E-002, 0.269719E-002, 0.271751E-002, 0.273871E-002, 0.276082E-002, 0.278386E-002, 0.280784E-002, 0.283270E-002, 0.285839E-002, 0.288482E-002, 0.291194E-002, 0.293965E-002, 0.296791E-002, 0.299666E-002, 0.302585E-002, 0.305544E-002, 0.308537E-002, 0.311560E-002, 0.314608E-002, 0.317674E-002, 0.320750E-002, 0.323830E-002, 0.326904E-002, 0.329964E-002, 0.333001E-002, 0.336003E-002, 0.338960E-002, 0.341862E-002, 0.344696E-002, 0.347451E-002, 0.350116E-002, 0.352677E-002, 0.355123E-002, 0.357442E-002, 0.359622E-002, 0.361653E-002, 0.363522E-002, 0.365220E-002, 0.366736E-002, 0.368062E-002, 0.369190E-002, 0.370112E-002, 0.370823E-002, 0.371317E-002, 0.371590E-002, 0.371642E-002, 0.371469E-002, 0.371074E-002, 0.370457E-002, 0.369621E-002, 0.368570E-002, 0.367303E-002])/one
t = np.linspace(14.3, 17.9, 101)

# Plot.
fig1, ax1 = plt.subplots(1, 1, figsize=(6, 5))
fig2, ax2 = plt.subplots(1, 1, figsize=(6, 5))

ax1.plot(t, speed, c='C0')
ax1.hlines(speed[0], 14.3, 17.9, colors='C0', linestyles='dotted', alpha=0.5)
ax1.set_xlim([14.3-0.1, 17.9+0.1])
ax1.set_ylim([0, np.max(speed)*1.1])
ax1.set_xlabel(r'$t$ (minutes)')
ax1.set_ylabel(r'$\bar{v}(\Omega)$')
ax1.set_title(r'Evolution of $\bar{v}(\Omega)$ through a contraction', fontsize=16)
ax1.ticklabel_format(style="sci", axis='y', scilimits=(-3, -3))
ax1.minorticks_on()

# ax1.vlines(t[np.argmin(speed)], 0, np.max(speed)*1.1, colors='gray', linestyles='dotted', alpha=0.5)
# ax1.hlines(speed[np.argmin(speed)], 14.3, 17.9, colors='C0', linestyles='dotted', alpha=0.5)

# print(f"{t[np.argmin(speed)]}")

ax2.plot(t, uptake, c='C1')
ax2.hlines(uptake[0], 14.3, 17.9, colors='C1', linestyles='dotted', alpha=0.5)
ax2.set_xlim([14.3-0.1, 17.9+0.1])
ax2.set_ylim([0, np.max(uptake)*1.1])
ax2.set_xlabel(r'$t$ (minutes)')
ax2.set_ylabel(r'$\bar{c}$')
ax2.set_title(r'Evolution of $\bar{c}$ through a contraction', fontsize=16)
ax2.ticklabel_format(style="sci", axis='y', scilimits=(-3, -3))
ax2.minorticks_on()

# Integrate the uptake through time.
dt = t[1] - t[0]
uptake_integral  = np.sum(uptake)*dt
uptake_integral0 = len(t-1)*uptake[0]*dt

print(f"Integral of uptake: {uptake_integral}")
print(f"Integral of uptake at t=0: {uptake_integral0}")
print(f"Ratio: {uptake_integral/uptake_integral0}")