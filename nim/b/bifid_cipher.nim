## Fixed-square Bifid fractionation over one complete message block.
proc bifidLetterIndex(value: int64, mergeJ: bool): int64 =
  var normalized = value
  if normalized >= 97 and normalized <= 122: normalized -= 32
  if normalized < 65 or normalized > 90: return -1
  var index = normalized - 65
  if index == 9:
    if not mergeJ: return -1
    index = 8
  elif index > 9:
    dec index
  index

proc bifidLetter(index: int): uint8 =
  var value = 97 + index
  if index >= 9: inc value
  uint8(value)

proc bifidCipher*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "bifid_cipher".} =
  if input == nil or length < 2 or length > 258: return -1
  let mode = input[0]
  let textLengthValue = input[1]
  if (mode != 0 and mode != 1) or textLengthValue < 0 or textLengthValue > 256: return -1
  let textLength = int(textLengthValue)
  if length != csize_t(textLength + 2): return -1

  var rows: array[256, uint8]
  var columns: array[256, uint8]
  var coordinates: array[512, uint8]
  var encoded: array[256, uint8]
  var resultLength = 0

  if mode == 0:
    for i in 0 ..< textLength:
      let value = input[i + 2]
      if value == 32: continue
      let letterIndex = bifidLetterIndex(value, true)
      if letterIndex < 0: return -1
      rows[resultLength] = uint8(letterIndex div 5 + 1)
      columns[resultLength] = uint8(letterIndex mod 5 + 1)
      inc resultLength
    for i in 0 ..< resultLength:
      coordinates[i] = rows[i]
      coordinates[resultLength + i] = columns[i]
    for i in 0 ..< resultLength:
      let row = int(coordinates[2 * i] - 1)
      let column = int(coordinates[2 * i + 1] - 1)
      encoded[i] = bifidLetter(row * 5 + column)
  else:
    resultLength = textLength
    for i in 0 ..< textLength:
      let letterIndex = bifidLetterIndex(input[i + 2], false)
      if letterIndex < 0: return -1
      coordinates[2 * i] = uint8(letterIndex div 5 + 1)
      coordinates[2 * i + 1] = uint8(letterIndex mod 5 + 1)
    for i in 0 ..< resultLength:
      let row = int(coordinates[i] - 1)
      let column = int(coordinates[resultLength + i] - 1)
      encoded[i] = bifidLetter(row * 5 + column)

  if outputCapacity < csize_t(resultLength) or (resultLength > 0 and output == nil): return -2
  for i in 0 ..< resultLength: output[i] = encoded[i]
  int64(resultLength)
