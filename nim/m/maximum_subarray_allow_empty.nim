const MaxLength = 1024

proc maximum_subarray_allow_empty*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "maximum_subarray_allow_empty".} =
  if length > csize_t(MaxLength) or (length > 0 and values == nil): return -1
  for index in 0 ..< int(length):
    if values[index] < int64(low(int32)) or values[index] > int64(high(int32)): return -1
  var current = 0'i64
  var best = 0'i64
  for index in 0 ..< int(length):
    current += values[index]
    if current < 0: current = 0
    if current > best: best = current
  best
