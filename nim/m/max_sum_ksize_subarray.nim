## Maximum sum of a fixed-size window; the final packed value is k.
proc max_sum_ksize_subarray*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "max_sum_ksize_subarray".} =
  if length == 0 or length > 64 or values == nil: return -1
  let arrayLength = int(length) - 1
  let kValue = values[arrayLength]
  if kValue < 0 or kValue > int64(arrayLength): return -1
  for index in 0 ..< arrayLength:
    if values[index] < -1000000 or values[index] > 1000000: return -1
  if kValue == 0: return 0

  let k = int(kValue)
  var windowSum = 0'i64
  for index in 0 ..< k: windowSum += values[index]
  var maximumSum = windowSum
  for index in k ..< arrayLength:
    windowSum += values[index] - values[index - k]
    if windowSum > maximumSum: maximumSum = windowSum
  maximumSum
