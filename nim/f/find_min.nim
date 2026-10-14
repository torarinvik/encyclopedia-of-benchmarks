## Return the smallest signed value in a nonempty array.
proc find_min*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "find_min".} =
  if length == 0 or length > 512: return -1
  var result = values[0]
  var index = csize_t(1)
  while index < length:
    if values[index] < result: result = values[index]
    inc index
  result
