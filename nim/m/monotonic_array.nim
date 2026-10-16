proc is_monotonic*(values: ptr UncheckedArray[int64], length: csize_t): int64 {.cdecl, exportc: "is_monotonic".} =
  if length > 256 or (values == nil and length != 0):
    return -1

  var i = 1
  while i < int(length):
    if values[i - 1] > values[i]:
      var j = 1
      while j < int(length):
        if values[j - 1] < values[j]:
          return 0
        inc j
      return 1
    inc i
  return 1
