## Return the largest signed value in a nonempty array.
proc find_max*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "find_max".} =
  if length == 0 or length > 512: return -1
  var result = values[0]
  var index = csize_t(1)
  while index < length:
    if values[index] > result: result = values[index]
    inc index
  result
