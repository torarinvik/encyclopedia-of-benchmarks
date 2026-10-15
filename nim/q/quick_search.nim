## Return the first ASCII byte match using a lookahead-byte shift table.
type
  I64Input = ptr UncheckedArray[int64]

proc quick_search*(values: I64Input, length: csize_t): int64
    {.cdecl, exportc: "quick_search".} =
  if values.isNil or length < 2 or length > 512: return -1
  if values[0] < 0 or values[0] > 255 or values[1] < 0 or values[1] > 255: return -1
  let textLength = int(values[0])
  let patternLength = int(values[1])
  if length != csize_t(2 + textLength + patternLength): return -1
  for index in 0 ..< textLength + patternLength:
    if values[2 + index] < 0 or values[2 + index] > 127: return -1
  if patternLength == 0: return 0
  if patternLength > textLength: return -1

  var shift: array[128, int]
  for byte in 0 ..< 128: shift[byte] = patternLength
  let patternStart = 2 + textLength
  for index in 0 ..< patternLength:
    shift[int(values[patternStart + index])] = patternLength - index

  var position = 0
  while position <= textLength - patternLength:
    var index = patternLength
    while index > 0 and values[2 + position + index - 1] == values[patternStart + index - 1]:
      dec index
    if index == 0: return int64(position)
    if position + patternLength >= textLength: break
    position += shift[int(values[2 + position + patternLength])]
  -1
