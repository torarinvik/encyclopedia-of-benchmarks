proc min_sum_ksize_subarray*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "min_sum_ksize_subarray".} =
  const invalid = low(int64)
  if values.isNil or length < 2 or length > 100002: return invalid
  let nValue = values[0]
  let kValue = values[1]
  if nValue < 0 or nValue > 100000 or kValue < 0 or kValue > 100000: return invalid
  let n = int(nValue)
  let k = int(kValue)
  if length != csize_t(n + 2): return invalid
  for i in 0 ..< n:
    if values[i + 2] < -10000 or values[i + 2] > 10000: return invalid
  if k > n: return -1
  var windowSum = 0'i64
  for i in 0 ..< k: windowSum += values[i + 2]
  var minimumSum = windowSum
  for i in k ..< n:
    windowSum += values[i + 2] - values[i - k + 2]
    minimumSum = min(minimumSum, windowSum)
  minimumSum
