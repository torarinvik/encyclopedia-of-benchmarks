proc isAsciiWhitespace(value: int64): bool =
  value == 32 or (value >= 9 and value <= 13)

proc longest_word_in_sentence*(values: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "longest_word_in_sentence".} =
  if values == nil or length < 1 or values[0] < 0 or values[0] > 1024 or
      length != csize_t(1 + values[0]):
    return -1
  let textLength = int(values[0])
  for index in 0 ..< textLength:
    let byte = values[index + 1]
    if not isAsciiWhitespace(byte) and (byte < 33 or byte > 126):
      return -1

  var bestStart = 0
  var bestLength = 0
  var index = 0
  while index < textLength:
    if isAsciiWhitespace(values[index + 1]):
      inc index
    else:
      let start = index
      while index < textLength and not isAsciiWhitespace(values[index + 1]):
        inc index
      let wordLength = index - start
      if wordLength > bestLength:
        bestStart = start
        bestLength = wordLength
  if csize_t(bestLength) > outputCapacity or (bestLength > 0 and output == nil):
    return -2
  for byte in 0 ..< bestLength:
    output[byte] = uint8(values[1 + bestStart + byte])
  int64(bestLength)
