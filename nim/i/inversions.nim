proc inversions*(values: ptr UncheckedArray[int64], length: csize_t): int64 {.cdecl, exportc: "inversions".} =
  if length > 1024 or (length != 0 and values == nil): return -1
  for i in 0 ..< int(length):
    if values[i] < low(int32).int64 or values[i] > high(int32).int64: return -1
  var count = 0'i64
  for i in 0 ..< int(length):
    for j in i + 1 ..< int(length):
      if values[i] > values[j]: inc count
  count
