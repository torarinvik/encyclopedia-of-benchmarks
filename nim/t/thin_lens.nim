proc thin_lens*(values: ptr UncheckedArray[int64], length: csize_t): float64
    {.cdecl, exportc: "thin_lens".} =
  const invalid = -1.0e300
  if values == nil or length != 3: return invalid
  let operation = values[0]
  let a = values[1]
  let b = values[2]
  if a < -1000 or a > 1000 or b < -1000 or b > 1000: return invalid
  if operation == 0:
    if a == 0 or b == 0 or a == b: return invalid
    let f = float64(a)
    let u = float64(b)
    return 1.0 / ((1.0 / f) - (1.0 / u))
  if operation == 1:
    if b == 0: return invalid
    return float64(a) / float64(b)
  if operation == 2:
    if b != 0: return invalid
    return if a > 0: 1.0 else: 0.0
  invalid
