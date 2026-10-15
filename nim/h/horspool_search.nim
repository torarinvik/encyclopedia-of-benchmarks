proc horspool_search*(packed: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "horspool_search".} =
  if length < 2:
    return -2
  let textLengthValue = packed[0]
  let patternLengthValue = packed[1]
  if textLengthValue < 0 or textLengthValue > 512 or patternLengthValue < 0 or patternLengthValue > 64:
    return -2
  let textLength = int(textLengthValue)
  let patternLength = int(patternLengthValue)
  if length != csize_t(textLength + patternLength + 2):
    return -2
  let patternStart = 2 + textLength
  for index in 0 ..< textLength:
    if packed[index + 2] < 0 or packed[index + 2] > 127:
      return -2
  for index in 0 ..< patternLength:
    if packed[patternStart + index] < 0 or packed[patternStart + index] > 127:
      return -2
  if patternLength == 0 or patternLength > textLength:
    return -1
  var shifts: array[128, int]
  for ch in 0 ..< 128: shifts[ch] = patternLength
  for index in countdown(patternLength - 2, 0):
    let ch = int(packed[patternStart + index])
    if shifts[ch] == patternLength:
      shifts[ch] = patternLength - 1 - index
  var endIndex = patternLength - 1
  while endIndex < textLength:
    var offset = 0
    while offset < patternLength and packed[patternStart + patternLength - 1 - offset] == packed[2 + endIndex - offset]:
      inc offset
    if offset == patternLength:
      return int64(endIndex - patternLength + 1)
    endIndex += shifts[int(packed[2 + endIndex])]
  -1
