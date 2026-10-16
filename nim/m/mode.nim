## Find the unique mode of a bounded array of small nonnegative integers.
proc mode*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "mode".} =
  if values.isNil or length == 0 or length > 4096: return -1
  var counts: array[256, int]
  for index in 0 ..< int(length):
    let value = values[index]
    if value < 0 or value > 255: return -1
    inc counts[int(value)]
  var maximum = 0
  var result: int64 = -1
  var unique = true
  for value in 0 ..< counts.len:
    if counts[value] > maximum:
      maximum = counts[value]
      result = int64(value)
      unique = true
    elif counts[value] != 0 and counts[value] == maximum:
      unique = false
  if unique: result else: -1
