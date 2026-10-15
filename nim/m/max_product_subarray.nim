const InvalidResult = low(int64)

proc max_product_subarray*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "max_product_subarray".} =
  if length > 9 or (length > 0 and values == nil): return InvalidResult
  if length == 0: return 0
  if values[0] < -10 or values[0] > 10: return InvalidResult
  var maxNow = values[0]
  var minNow = values[0]
  var maxProduct = values[0]
  for i in 1 ..< int(length):
    let value = values[i]
    if value < -10 or value > 10: return InvalidResult
    if value < 0: swap(maxNow, minNow)
    maxNow = max(value, maxNow * value)
    minNow = min(value, minNow * value)
    maxProduct = max(maxProduct, maxNow)
  maxProduct
