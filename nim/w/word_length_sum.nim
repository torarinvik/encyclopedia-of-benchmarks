## Go Problem17: sum byte lengths after splitting on ASCII space.
proc word_length_sum*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "word_length_sum".} =
  if length > 4096 or (length != 0 and values.isNil): return -1
  var total = 0'i64
  for index in 0 ..< int(length):
    if values[index] < 0 or values[index] > 255: return -1
    if values[index] != 32: inc total
  total
