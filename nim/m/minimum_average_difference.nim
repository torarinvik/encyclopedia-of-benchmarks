## Return the earliest split with the smallest difference of integer averages.
const MaxLength = 100_000
const MaxValue = 100_000'i64

proc minimum_average_difference*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "minimum_average_difference".} =
  if values == nil or length == 0 or length > MaxLength: return -1
  let n = int(length)
  var totalSum = 0'i64
  for index in 0 ..< n:
    if values[index] < 0 or values[index] > MaxValue: return -1
    totalSum += values[index]
  var prefixSum = 0'i64
  var bestDifference = high(int64)
  var bestIndex = 0
  for index in 0 ..< n:
    prefixSum += values[index]
    let leftAverage = prefixSum div int64(index + 1)
    let suffixLength = n - index - 1
    let rightAverage = if suffixLength == 0: 0'i64 else: (totalSum - prefixSum) div int64(suffixLength)
    let difference = abs(leftAverage - rightAverage)
    if difference < bestDifference:
      bestDifference = difference
      bestIndex = index
  int64(bestIndex)
