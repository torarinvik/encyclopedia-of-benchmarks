## Exact-equality reciprocal progression predicate for IEEE-754 inputs.
proc is_harmonic_series*(values: ptr UncheckedArray[int64], length: csize_t): float64
    {.cdecl, exportc: "is_harmonic_series".} =
  const maxValues = 32
  const invalidResult = -1.0e300
  if values == nil or length < 2 or length > maxValues + 1: return invalidResult
  let count = values[0]
  if count < 1 or count > maxValues or length != csize_t(count + 1): return invalidResult

  var reciprocals: array[maxValues, float64]
  for i in 0 ..< int(count):
    let value = cast[float64](values[i + 1])
    if value == 0.0: return invalidResult
    reciprocals[i] = 1.0 / value
  if count == 1: return 1.0
  let commonDifference = reciprocals[1] - reciprocals[0]
  for i in 2 ..< int(count):
    if reciprocals[i] - reciprocals[i - 1] != commonDifference: return 0.0
  1.0
