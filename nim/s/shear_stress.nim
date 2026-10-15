## Shear stress, force, and area relation over a bounded integer-valued domain.
proc shear_stress*(stress, tangential_force, area: float64): float64
    {.cdecl, exportc: "shear_stress".} =
  if stress != stress or tangential_force != tangential_force or area != area: return -1.0
  if stress < 0.0 or stress > 1000.0 or tangential_force < 0.0 or tangential_force > 1000.0 or area < 0.0 or area > 1000.0: return -1.0
  if stress != float64(int64(stress)) or tangential_force != float64(int64(tangential_force)) or area != float64(int64(area)): return -1.0
  let zeros = (if stress == 0.0: 1 else: 0) + (if tangential_force == 0.0: 1 else: 0) + (if area == 0.0: 1 else: 0)
  if zeros != 1: return -1.0
  if stress == 0.0: return tangential_force / area
  if tangential_force == 0.0: return stress * area
  tangential_force / stress
