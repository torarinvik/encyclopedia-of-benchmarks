## Return the longest strictly increasing contiguous run.
const MaxLength = 10_000

proc longest_continuous_increasing_subsequence*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "longest_continuous_increasing_subsequence".} =
  if length > csize_t(MaxLength) or (length != 0 and values == nil): return -1
  for index in 0 ..< int(length):
    if values[index] < -1_000_000 or values[index] > 1_000_000: return -1
  if length == 0: return 0

  var current = 1'i64
  var best = 1'i64
  for index in 1 ..< int(length):
    if values[index] > values[index - 1]: inc current
    else: current = 1
    if current > best: best = current
  return best
