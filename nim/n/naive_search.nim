type
  I64Input = ptr UncheckedArray[int64]
  ByteOutput = ptr UncheckedArray[uint8]

const MaxInputValues = 512

proc naive_search*(values: I64Input, length: csize_t, output: ByteOutput,
                   outputCapacity: csize_t): int64 {.cdecl, exportc: "naive_search".} =
  if values == nil or length < 2 or length > MaxInputValues: return -1
  if values[0] < 0 or values[0] > 255 or values[1] < 0 or values[1] > 255: return -1
  let textLength = int(values[0])
  let patternLength = int(values[1])
  if length != csize_t(2 + textLength + patternLength): return -1
  let patternStart = 2 + textLength
  for index in 0 ..< textLength:
    if values[2 + index] < 1 or values[2 + index] > 127: return -1
  for index in 0 ..< patternLength:
    if values[patternStart + index] < 1 or values[patternStart + index] > 127: return -1

  var matchCount = 0
  if patternLength <= textLength:
    for start in 0 .. textLength - patternLength:
      var offset = 0
      while offset < patternLength and values[2 + start + offset] == values[patternStart + offset]:
        inc offset
      if offset == patternLength: inc matchCount
  if outputCapacity < csize_t(matchCount) or (matchCount != 0 and output == nil): return -2
  var written = 0
  if patternLength <= textLength:
    for start in 0 .. textLength - patternLength:
      var offset = 0
      while offset < patternLength and values[2 + start + offset] == values[patternStart + offset]:
        inc offset
      if offset == patternLength:
        output[written] = uint8(start)
        inc written
  int64(written)
