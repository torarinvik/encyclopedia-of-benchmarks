proc neville*(values: ptr UncheckedArray[int64], length: csize_t): float64 {.cdecl, exportc: "neville".} =
  const invalid = -1.0e300
  if values == nil or length < 4 or length > 34: return invalid
  let count = values[0]
  let targetI = values[1]
  if count < 1 or count > 16 or length != csize_t(2 * count + 2) or targetI < -1_000_000 or targetI > 1_000_000: return invalid
  var x, p: array[16, float64]
  for i in 0 ..< int(count):
    let xi = values[2 + 2 * i]
    let yi = values[3 + 2 * i]
    if xi < -1_000_000 or xi > 1_000_000 or yi < -1_000_000 or yi > 1_000_000: return invalid
    for j in 0 ..< i:
      if values[2 + 2 * j] == xi: return invalid
    x[i] = float64(xi)
    p[i] = float64(yi)
  let target = float64(targetI)
  for k in 1 ..< int(count):
    for i in 0 ..< int(count) - k:
      p[i] = ((target - x[i + k]) * p[i] + (x[i] - target) * p[i + 1]) / (x[i] - x[i + k])
  return p[0]
