const MaxLength = 4096

proc check_snake_case*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "check_snake_case".} =
  if length > csize_t(MaxLength) or (length != 0 and values == nil): return -2
  var found = 0'i64
  for index in 0 ..< int(length):
    let value = values[index]
    if value < 32 or value > 126: return -2
    if value == 95: found = 1
  found
