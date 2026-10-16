import std/math

proc rayleigh_quotient*(values: ptr UncheckedArray[float64], length: csize_t,
    output: ptr UncheckedArray[float64], capacity: csize_t): int64 {.cdecl, exportc: "rayleigh_quotient".} =
  if values == nil or length < 1 or length > 273: return -1
  for i in 0 ..< int(length):
    if values[i] != values[i]: return -1

  let nValue = values[0]
  if nValue < 1.0 or nValue > 16.0 or floor(nValue) != nValue: return -1
  let n = int(nValue)
  if length != csize_t(1 + n * n + n): return -1
  let matrixStart = 1
  let vectorStart = 1 + n * n

  for row in 0 ..< n:
    for col in 0 ..< n:
      let value = values[matrixStart + row * n + col]
      if value < -1000.0 or value > 1000.0: return -1
      if col > row and value != values[matrixStart + col * n + row]: return -1

  var denominator = 0.0
  for i in 0 ..< n:
    let value = values[vectorStart + i]
    if value < -100.0 or value > 100.0: return -1
    denominator += value * value
  if denominator <= 0.0: return -1

  var numerator = 0.0
  for col in 0 ..< n:
    var vStarDot = 0.0
    for row in 0 ..< n:
      vStarDot += values[vectorStart + row] * values[matrixStart + row * n + col]
    numerator += vStarDot * values[vectorStart + col]
  let quotient = numerator / denominator

  if output == nil or capacity < 1: return -2
  output[0] = quotient
  1
