const MaxLength = 4096

proc is_lower*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "is_lower".} =
  if length > csize_t(MaxLength) or (length != 0 and values == nil): return -1
  for index in 0 ..< int(length):
    let value = values[index]
    if value < 32 or value > 126: return -1
    if value >= 65 and value <= 90: return 0
  1
