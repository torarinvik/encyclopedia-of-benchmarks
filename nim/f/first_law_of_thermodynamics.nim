proc first_law_of_thermodynamics*(operation, a, b: float64): float64
    {.cdecl, exportc: "first_law_of_thermodynamics".} =
  if operation != operation or a != a or b != b: return -1e300
  if operation < 0.0 or operation > 2.0 or operation != float64(int64(operation)): return -1e300
  if a < -1000000.0 or a > 1000000.0 or b < -1000000.0 or b > 1000000.0: return -1e300
  if a != float64(int64(a)) or b != float64(int64(b)): return -1e300
  if operation == 0.0: return a - b
  if operation == 1.0: return a + b
  a - b
