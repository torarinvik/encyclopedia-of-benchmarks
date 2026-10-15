## Return the greatest absolute coordinate difference from packed points.
proc chebyshev_distance*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "chebyshev_distance".} =
  if length < 3: return -1
  let dimension_value = values[0]
  if dimension_value < 1 or dimension_value > 128: return -1
  let dimension = csize_t(dimension_value)
  if length != 1 + 2 * dimension: return -1
  var maximum: int64 = 0
  var i: csize_t = 0
  while i < dimension:
    let a = values[1 + i]
    let b = values[1 + dimension + i]
    if a < -1_000_000_000 or a > 1_000_000_000 or b < -1_000_000_000 or b > 1_000_000_000: return -1
    var difference = a - b
    if difference < 0: difference = -difference
    if difference > maximum: maximum = difference
    inc i
  maximum
