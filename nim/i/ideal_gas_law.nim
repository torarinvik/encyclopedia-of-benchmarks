## Solve one ideal-gas-law variable using a portable operation selector.
proc ideal_gas_law*(values: ptr UncheckedArray[int64], length: csize_t): float64
    {.cdecl, exportc: "ideal_gas_law".} =
  if length != 4 or values == nil: return -1.0e300
  let operation = values[0]
  let a = values[1]
  let b = values[2]
  let c = values[3]
  if operation < 0 or operation > 3 or a < 0 or a > 1000 or b < 0 or b > 1000 or c < 0 or c > 1000:
    return -1.0e300
  if operation == 0 or operation == 1:
    if c == 0: return -1.0e300
    return (float64(a) * float64(b) * 8.314462) / float64(c)
  if a == 0: return -1.0e300
  (float64(c) * float64(b)) / (float64(a) * 8.314462)
