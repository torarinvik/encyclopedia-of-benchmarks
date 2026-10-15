proc max_sum_sliding_window*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "max_sum_sliding_window".} =
  const invalid = low(int64)
  if values.isNil or length < 3 or length > 100002: return invalid
  let nValue = values[0]
  let kValue = values[1]
  if nValue < 1 or nValue > 100000 or kValue < 1 or kValue > nValue: return invalid
  let n = int(nValue)
  let k = int(kValue)
  if length != csize_t(n + 2): return invalid
  var currentSum = 0'i64
  for i in 0 ..< n:
    let value = values[i + 2]
    if value < -1000000000 or value > 1000000000: return invalid
    if i < k: currentSum += value
  var maximumSum = currentSum
  for i in 0 ..< n - k:
    currentSum = currentSum - values[i + 2] + values[i + k + 2]
    maximumSum = max(maximumSum, currentSum)
  maximumSum
