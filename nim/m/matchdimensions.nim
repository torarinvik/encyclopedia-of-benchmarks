proc matchdimensions*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "matchdimensions".} =
  if values == nil or length != 4: return -1
  for index in 0 ..< 4:
    if values[index] < 0 or values[index] > 65535: return -1
  if values[0] == values[2] and values[1] == values[3]: 1 else: 0
