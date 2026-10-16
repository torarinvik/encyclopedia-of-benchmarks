proc longest_consecutive_characters*(values: ptr UncheckedArray[int64], length: csize_t,
                                     output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "longest_consecutive_characters".} =
  if values == nil or length < 1 or length > 257: return -1
  let countValue = values[0]
  if countValue < 1 or countValue > 256 or length != csize_t(countValue + 1): return -1
  let count = int(countValue)
  for index in 0 ..< count:
    if values[index + 1] < 0 or values[index + 1] > 127: return -1
  if output == nil or capacity < 3: return -2

  var bestCharacter = values[1]
  var bestLength = 1
  var currentLength = 1
  for index in 1 ..< count:
    if values[index + 1] == values[index]:
      inc currentLength
      if currentLength > bestLength:
        bestLength = currentLength
        bestCharacter = values[index + 1]
    else:
      currentLength = 1
  output[0] = uint8(bestCharacter)
  output[1] = uint8(bestLength and 255)
  output[2] = uint8(bestLength shr 8)
  3
