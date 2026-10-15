## Ohm's law over a bounded integer-valued input domain.
proc ohms_law*(voltage, current, resistance: float64): float64
    {.cdecl, exportc: "ohms_law".} =
  if voltage != voltage or current != current or resistance != resistance: return -1e300
  if voltage < -1000.0 or voltage > 1000.0 or current < -1000.0 or current > 1000.0 or resistance < 0.0 or resistance > 1000.0: return -1e300
  if voltage != float64(int64(voltage)) or current != float64(int64(current)) or resistance != float64(int64(resistance)): return -1e300
  let zeros = (if voltage == 0.0: 1 else: 0) + (if current == 0.0: 1 else: 0) + (if resistance == 0.0: 1 else: 0)
  if zeros != 1: return -1e300
  if voltage == 0.0: return current * resistance
  if current == 0.0: return voltage / resistance
  voltage / current
