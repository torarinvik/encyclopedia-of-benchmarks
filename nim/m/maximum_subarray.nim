## Kadane's maximum nonempty contiguous-subarray sum.
proc maximum_subarray*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "maximum_subarray".} =
  if length == 0 or length > 1024:
    return -1
  var index = csize_t(0)
  while index < length:
    if values[index] < -2147483648'i64 or values[index] > 2147483647'i64:
      return -1
    inc index
  var current = values[0]
  var best = current
  index = 1
  while index < length:
    if current > 0:
      current += values[index]
    else:
      current = values[index]
    if current > best:
      best = current
    inc index
  best
