const MaxInputLength = 9
const InvalidResult = low(int64)

proc maximum_product_subarray*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "maximum_product_subarray".} =
  if values.isNil or length == 0 or length > MaxInputLength: return InvalidResult
  for i in 0 ..< int(length):
    if values[i] < -10'i64 or values[i] > 10'i64: return InvalidResult

  var currentMax = values[0]
  var currentMin = values[0]
  var best = values[0]
  for i in 1 ..< int(length):
    let value = values[i]
    let priorMax = currentMax
    let priorMin = currentMin
    let fromMax = priorMax * value
    let fromMin = priorMin * value
    currentMax = max(value, max(fromMax, fromMin))
    currentMin = min(value, min(fromMax, fromMin))
    best = max(best, currentMax)
  best
