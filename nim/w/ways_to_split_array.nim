## Count positions where the prefix sum is at least the remaining suffix sum.
const MaxLength = 100_000
const MaxValue = 100_000'i64

proc ways_to_split_array*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "ways_to_split_array".} =
  if values == nil or length < 2 or length > MaxLength: return -1
  let n = int(length)
  var totalSum = 0'i64
  for index in 0 ..< n:
    if values[index] < -MaxValue or values[index] > MaxValue: return -1
    totalSum += values[index]
  var prefixSum = 0'i64
  var ways = 0'i64
  for index in 0 ..< n - 1:
    prefixSum += values[index]
    if prefixSum >= totalSum - prefixSum: inc ways
  ways
