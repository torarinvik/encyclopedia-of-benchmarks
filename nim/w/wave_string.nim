const MaxTextLength = 512

proc isAsciiLetter(value: int64): bool =
  (value >= 65 and value <= 90) or (value >= 97 and value <= 122)

proc wave_string*(values: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "wave_string".} =
  if values == nil or length < 1 or values[0] < 0 or values[0] > MaxTextLength or
      length != csize_t(1 + values[0]):
    return -1
  let textLength = int(values[0])
  var letterCount = 0
  for index in 0 ..< textLength:
    let byte = values[index + 1]
    if byte < 32 or byte > 126:
      return -1
    if isAsciiLetter(byte):
      inc letterCount
  let outputLength = letterCount * (textLength + 2)
  if csize_t(outputLength) > outputCapacity or (outputLength > 0 and output == nil):
    return -2

  var written = 0
  for position in 0 ..< textLength:
    if not isAsciiLetter(values[position + 1]):
      continue
    output[written] = uint8(textLength and 255)
    output[written + 1] = uint8(textLength shr 8)
    written += 2
    for index in 0 ..< textLength:
      var byte = values[index + 1]
      if index == position and byte >= 97 and byte <= 122:
        byte -= 32
      output[written] = uint8(byte)
      inc written
  int64(letterCount)
