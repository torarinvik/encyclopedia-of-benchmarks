proc is_sorted*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "is_sorted".} =
  if length > 4096 or (length > 0 and values.isNil): return -1
  let count = int(length)
  for index in 0 ..< count:
    if values[index] < -2_147_483_648'i64 or values[index] > 2_147_483_647'i64: return -1
  var index = 1
  while index < count:
    if values[index] < values[index - 1]: return 0
    inc index
  1
