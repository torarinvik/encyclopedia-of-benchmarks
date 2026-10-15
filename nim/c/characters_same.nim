proc characters_same*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "characters_same".} =
  if length > 256 or (length > 0 and values == nil): return -1
  for index in 0 ..< int(length):
    if values[index] < 0 or values[index] > 127: return -1
  if length == 0: return 1
  let first = values[0]
  for index in 1 ..< int(length):
    if values[index] != first: return 0
  1
