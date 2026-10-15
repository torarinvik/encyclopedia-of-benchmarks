## Check whether the bounded ASCII input is entirely lowercase letters.
const MaxLength = 4096

proc check_flat_case*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "check_flat_case".} =
  if length > csize_t(MaxLength) or (length != 0 and values == nil): return -2
  for index in 0 ..< int(length):
    let value = values[index]
    if value < 32 or value > 126: return -2
  for index in 0 ..< int(length):
    let value = values[index]
    if value < 97 or value > 122: return 0
  1
