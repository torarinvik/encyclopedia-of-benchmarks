const MaxInputLength = 64
const InvalidResult = low(int64)

proc maximum_circular_subarray*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "maximum_circular_subarray".} =
  if values.isNil or length == 0 or length > MaxInputLength: return InvalidResult
  for i in 0 ..< int(length):
    if values[i] < -1_000_000'i64 or values[i] > 1_000_000'i64: return InvalidResult

  var total = values[0]
  var currentMax = values[0]
  var maxSoFar = values[0]
  var currentMin = values[0]
  var minSoFar = values[0]
  for i in 1 ..< int(length):
    let value = values[i]
    currentMax = max(currentMax + value, value)
    maxSoFar = max(maxSoFar, currentMax)
    currentMin = min(currentMin + value, value)
    minSoFar = min(minSoFar, currentMin)
    total += value
  if minSoFar == total: return maxSoFar
  max(maxSoFar, total - minSoFar)
