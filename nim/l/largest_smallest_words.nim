proc isStrippedPunctuation(value: int64): bool =
  value == int64(ord('.')) or value == int64(ord(',')) or value == int64(ord('!')) or
    value == int64(ord('?')) or value == int64(ord('(')) or value == int64(ord(')')) or
    value == int64(ord('[')) or value == int64(ord(']')) or value == int64(ord('{')) or
    value == int64(ord('}'))

proc putU32(output: ptr UncheckedArray[uint8], offset: int, value: uint32) =
  output[offset] = uint8(value and 0xff)
  output[offset + 1] = uint8((value shr 8) and 0xff)
  output[offset + 2] = uint8((value shr 16) and 0xff)
  output[offset + 3] = uint8((value shr 24) and 0xff)

proc largest_smallest_words*(values: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "largest_smallest_words".} =
  if values == nil or length < 1 or length > 515 or values[0] < 1 or values[0] > 512 or
      length != csize_t(1 + values[0]):
    return -1
  let textLength = int(values[0])
  var text: array[512, uint8]
  for index in 0 ..< textLength:
    let value = values[index + 1]
    if value < 32 or value > 126: return -1
    text[index] = uint8(value)

  var smallStart = 0
  var largeStart = 0
  var smallLength = 513
  var largeLength = 0
  var wordCount = 0
  var pos = 0
  while pos < textLength:
    while pos < textLength and text[pos] == uint8(ord(' ')): inc pos
    if pos == textLength: break
    let tokenStart = pos
    while pos < textLength and text[pos] != uint8(ord(' ')): inc pos
    var first = tokenStart
    var last = pos
    while first < last and isStrippedPunctuation(int64(text[first])): inc first
    while last > first and isStrippedPunctuation(int64(text[last - 1])): dec last
    let wordLength = last - first
    if wordLength < smallLength:
      smallStart = first
      smallLength = wordLength
    if wordLength > largeLength:
      largeStart = first
      largeLength = wordLength
    inc wordCount
  if wordCount == 0: return -1
  let outputLength = 8 + smallLength + largeLength
  if csize_t(outputLength) > outputCapacity or output == nil: return -2
  putU32(output, 0, uint32(smallLength))
  for index in 0 ..< smallLength: output[4 + index] = text[smallStart + index]
  let largeHeader = 4 + smallLength
  putU32(output, largeHeader, uint32(largeLength))
  for index in 0 ..< largeLength: output[largeHeader + 4 + index] = text[largeStart + index]
  int64(outputLength)
