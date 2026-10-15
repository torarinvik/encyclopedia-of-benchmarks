## Count transitions from ASCII space to a non-space byte.
const MaxLength = 4096

proc count_segments*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "count_segments".} =
  if length > csize_t(MaxLength) or (length != 0 and input == nil): return -1
  var count = 0'i64
  var previousWasSpace = true
  for index in 0 ..< int(length):
    let value = input[index]
    if value < 1 or value > 127: return -1
    if value != 32 and previousWasSpace: count += 1
    previousWasSpace = value == 32
  count
