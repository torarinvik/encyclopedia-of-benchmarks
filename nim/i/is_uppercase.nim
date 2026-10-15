const MaxLength = 4096

proc is_uppercase*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "is_uppercase".} =
  if length > csize_t(MaxLength) or (length != 0 and values == nil): return -1
  for index in 0 ..< int(length):
    let value = values[index]
    if value < 32 or value > 126: return -1
    if value >= 97 and value <= 122: return 0
  1
