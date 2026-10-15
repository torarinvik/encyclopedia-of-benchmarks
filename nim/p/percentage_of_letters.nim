proc lowerAscii(value: int64): int64 =
  if value >= 65 and value <= 90: value + 32 else: value

proc percentage_of_letters*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "percentage_of_letters".} =
  if length < 2 or length > 4097 or values.isNil: return -1
  let target = lowerAscii(values[0])
  if target < 97 or target > 122: return -1
  let textLength = int(length) - 1
  var matches = 0
  for index in 0 ..< textLength:
    let value = values[index + 1]
    if value < 0 or value > 127: return -1
    if lowerAscii(value) == target: inc matches
  int64((100 * matches) div textLength)
