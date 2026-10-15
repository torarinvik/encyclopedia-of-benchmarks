## Return the n-dimensional Manhattan distance between two integer points.
proc manhattan_distance*(values: ptr UncheckedArray[int64], length: csize_t): float64
    {.cdecl, exportc: "manhattan_distance".} =
  if values == nil or length < 3: return -1.0e300
  let dimensions = values[0]
  if dimensions < 1 or dimensions > 16 or length != csize_t(1 + 2 * dimensions): return -1.0e300
  var total = 0'i64
  for index in 0 ..< int(dimensions):
    let first = values[1 + index]
    let second = values[1 + int(dimensions) + index]
    if first < -1_000_000 or first > 1_000_000 or second < -1_000_000 or second > 1_000_000: return -1.0e300
    let difference = first - second
    total += (if difference < 0: -difference else: difference)
  float64(total)
