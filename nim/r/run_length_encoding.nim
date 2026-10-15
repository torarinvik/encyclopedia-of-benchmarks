## Encode runs as an unambiguous decimal count followed by an ASCII byte.
proc runLengthEncoding*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "run_length_encoding".} =
  if length > 66: return -1
  for index in 0 ..< int(length):
    let value = input[index]
    if value < 1 or value > 127 or (value >= 48 and value <= 57): return -1

  var encodedLength = 0
  var index = 0
  while index < int(length):
    var ending = index + 1
    while ending < int(length) and input[ending] == input[index]: inc ending
    let count = ending - index
    encodedLength += (if count >= 10: 3 else: 2)
    index = ending
  if outputCapacity < csize_t(encodedLength): return -2

  var writeIndex = 0
  index = 0
  while index < int(length):
    var ending = index + 1
    while ending < int(length) and input[ending] == input[index]: inc ending
    let count = ending - index
    if count >= 10:
      output[writeIndex] = uint8(48 + count div 10)
      inc writeIndex
    output[writeIndex] = uint8(48 + count mod 10)
    inc writeIndex
    output[writeIndex] = uint8(input[index])
    inc writeIndex
    index = ending
  int64(writeIndex)
