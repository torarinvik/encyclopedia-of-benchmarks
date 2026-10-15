## Check that an integer factor list has no repeated values.
proc square_free_factor_list*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "square_free_factor_list".} =
  if length > 256 or (length != 0 and values == nil): return -1
  for i in 0 ..< int(length):
    if values[i] < -2_147_483_648'i64 or values[i] > 2_147_483_647'i64: return -1
    for j in 0 ..< i:
      if values[i] == values[j]: return 0
  return 1
