## Return the first lowercase ASCII letter whose frequency is one.
const MaxLength = 1024

proc first_unique_character*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "first_unique_character".} =
  if length > csize_t(MaxLength) or (length != 0 and values == nil): return -2
  var counts: array[26, int]
  for index in 0 ..< int(length):
    let value = values[index]
    if value < 97 or value > 122: return -2
    inc counts[int(value - 97)]
  for index in 0 ..< int(length):
    if counts[int(values[index] - 97)] == 1: return int64(index)
  -1
