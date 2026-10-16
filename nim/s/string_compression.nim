## Encode each run as its ASCII byte and, when repeated, its decimal count.
proc stringCompression*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "string_compression".} =
  if length > 64 or (length > 0 and input == nil): return -1
  for index in 0 ..< int(length):
    if input[index] < 0 or input[index] > 127: return -1

  var encodedLength = 0
  var index = 0
  while index < int(length):
    var ending = index + 1
    while ending < int(length) and input[ending] == input[index]: inc ending
    let count = ending - index
    encodedLength += 1
    if count > 1: encodedLength += (if count >= 10: 2 else: 1)
    index = ending
  if outputCapacity < csize_t(encodedLength) or (encodedLength > 0 and output == nil): return -2

  var writeIndex = 0
  index = 0
  while index < int(length):
    var ending = index + 1
    while ending < int(length) and input[ending] == input[index]: inc ending
    let count = ending - index
    output[writeIndex] = uint8(input[index])
    inc writeIndex
    if count > 1:
      if count >= 10:
        output[writeIndex] = uint8(48 + count div 10)
        inc writeIndex
      output[writeIndex] = uint8(48 + count mod 10)
      inc writeIndex
    index = ending
  int64(writeIndex)
