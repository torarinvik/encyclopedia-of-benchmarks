type
  I64Input = ptr UncheckedArray[int64]
  ByteOutput = ptr UncheckedArray[uint8]

const MaxInputValues = 512

proc countMatches(values: I64Input, textLength, patternLength, patternStart: int,
                  shifts: array[128, int]): int =
  if patternLength == 0: return textLength + 1
  if patternLength > textLength: return 0
  var count = 0
  var start = 0
  while start <= textLength - patternLength:
    var current = patternLength
    while current > 0 and values[patternStart + current - 1] == values[2 + start + current - 1]: dec current
    if current == 0:
      inc count
      inc start
    else:
      start += shifts[int(values[2 + start + patternLength - 1])]
  count

proc boyer_moore_horspool*(values: I64Input, length: csize_t, output: ByteOutput,
                           outputCapacity: csize_t): int64 {.cdecl, exportc: "boyer_moore_horspool".} =
  if values == nil or length < 2 or length > MaxInputValues: return -1
  if values[0] < 0 or values[0] > 255 or values[1] < 0 or values[1] > 255: return -1
  let textLength = int(values[0])
  let patternLength = int(values[1])
  if length != csize_t(2 + textLength + patternLength): return -1
  let patternStart = 2 + textLength
  for index in 0 ..< textLength + patternLength:
    if values[2 + index] < 0 or values[2 + index] > 127: return -1

  var shifts: array[128, int]
  for byte in 0 ..< 128: shifts[byte] = patternLength
  for index in 0 ..< patternLength - 1: shifts[int(values[patternStart + index])] = patternLength - 1 - index
  let matchCount = countMatches(values, textLength, patternLength, patternStart, shifts)
  if outputCapacity < csize_t(matchCount) or (matchCount != 0 and output == nil): return -2

  var written = 0
  if patternLength == 0:
    for position in 0 .. textLength:
      output[written] = uint8(position)
      inc written
  elif patternLength <= textLength:
    var start = 0
    while start <= textLength - patternLength:
      var current = patternLength
      while current > 0 and values[patternStart + current - 1] == values[2 + start + current - 1]: dec current
      if current == 0:
        output[written] = uint8(start)
        inc written
        inc start
      else:
        start += shifts[int(values[2 + start + patternLength - 1])]
  int64(written)
