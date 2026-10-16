const Invalid = -1.0e300
proc fractional_differentiation*(values: ptr UncheckedArray[int64], length: csize_t): float64 {.cdecl, exportc.} =
  if values == nil or length < 4 or length > 18: return Invalid
  let n = int(length) - 2
  let degree = values[0]
  let window = values[1]
  if degree < 0 or degree > 1_000_000 or window < 1 or window > 8 or n <= int(window) or n > 16: return Invalid
  for i in 0 ..< n:
    if values[i + 2] < -1_000_000 or values[i + 2] > 1_000_000: return Invalid
  let d = float64(degree) / 1_000_000.0
  var weights: array[8, float64]
  weights[0] = 1.0
  for k in 1 ..< int(window): weights[k] = -weights[k-1] * (d - float64(k) + 1.0) / float64(k)
  var result = 0.0
  for j in 0 ..< int(window): result += weights[j] * (float64(values[2+n-1-j]) / 1000.0)
  result
