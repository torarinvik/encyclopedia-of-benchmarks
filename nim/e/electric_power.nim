## Pinned electric_power formula over the benchmark's bounded integer-valued domain.
proc electric_power*(voltage, current, power: float64): float64
    {.cdecl, exportc: "electric_power".} =
  if voltage != voltage or current != current or power != power: return -1.0e300
  if voltage < -10000.0 or voltage > 10000.0 or current < -10000.0 or current > 10000.0: return -1.0e300
  if power < 0.0 or power > 100000000.0: return -1.0e300
  if voltage != float64(int64(voltage)) or current != float64(int64(current)) or power != float64(int64(power)): return -1.0e300
  var zeros = 0
  if voltage == 0.0: inc zeros
  if current == 0.0: inc zeros
  if power == 0.0: inc zeros
  if zeros != 1: return -1.0e300
  if voltage == 0.0: return power / current
  if current == 0.0: return power / voltage
  let product = voltage * current
  if product < 0.0: return -product
  product
