const MaxLength = 1024
const MaxAbsValue = 1_000_000'i64

proc maximum_subarray_int32*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "maximum_subarray_int32".} =
  if values == nil or length == 0 or length > csize_t(MaxLength): return -1
  for index in 0 ..< int(length):
    if values[index] < -MaxAbsValue or values[index] > MaxAbsValue: return -1
  var current = values[0]
  var best = current
  for index in 1 ..< int(length):
    if current > 0:
      current += values[index]
    else:
      current = values[index]
    if current > best: best = current
  best
