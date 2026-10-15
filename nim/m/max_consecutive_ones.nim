## Return the longest run of ones in a binary array.
proc max_consecutive_ones*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "max_consecutive_ones".} =
  if length > 4096: return -1
  var best = csize_t(0)
  var run = csize_t(0)
  var index = csize_t(0)
  while index < length:
    if values[index] != 0'i64 and values[index] != 1'i64: return -1
    if values[index] == 1:
      inc run
      if run > best: best = run
    else:
      run = 0
    inc index
  int64(best)
