## Three reciprocal thin-lens formula solves.
proc lens_formulae*(values: ptr UncheckedArray[int64], length: csize_t): float64
    {.cdecl, exportc: "lens_formulae".} =
  if length != 3 or values == nil: return -1.0e300
  let operation = values[0]
  let first = values[1]
  let second = values[2]
  if operation < 0 or operation > 2 or first == 0 or second == 0 or first < -1000000 or first > 1000000 or second < -1000000 or second > 1000000:
    return -1.0e300
  if operation == 0:
    if first == second: return -1.0e300
    return 1.0 / ((1.0 / float64(second)) - (1.0 / float64(first)))
  if operation == 1:
    if first == second: return -1.0e300
    return 1.0 / ((1.0 / float64(second)) - (1.0 / float64(first)))
  if first == -second: return -1.0e300
  1.0 / ((1.0 / float64(second)) + (1.0 / float64(first)))
