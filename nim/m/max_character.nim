proc max_character*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "max_character".} =
  if length == 0 or length > 256 or values == nil: return -1
  var counts: array[26, int64]
  for i in 0 ..< int(length):
    if values[i] < 97 or values[i] > 122: return -1
    inc counts[int(values[i] - 97)]
  var best = 0'i64
  var code = -1'i64
  var tied = false
  for i in 0 ..< 26:
    if counts[i] > best:
      best = counts[i]
      code = 97 + int64(i)
      tied = false
    elif counts[i] == best and best != 0:
      tied = true
  if tied: return -1
  code
