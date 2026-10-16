proc bit_array_count_zero_bits*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "bit_array_count_zero_bits".} =
  if length > 4096 or (length != 0 and values.isNil): return -1
  var zeroCount = 0'i64
  for index in 0 ..< int(length):
    if values[index] != 0 and values[index] != 1: return -1
    if values[index] == 0: inc zeroCount
  zeroCount
