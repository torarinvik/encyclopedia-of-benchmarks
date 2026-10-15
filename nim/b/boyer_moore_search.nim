## Return the first ASCII byte match using the bad-character rule.
proc boyer_moore_search*(inputValues: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "boyer_moore_search".} =
  if inputValues.isNil or length < 2 or length > 8194: return -1
  let textLengthValue = inputValues[0]
  let patternLengthValue = inputValues[1]
  if textLengthValue < 0 or textLengthValue > 4096 or patternLengthValue < 0 or patternLengthValue > 4096: return -1
  let textLength = int(textLengthValue)
  let patternLength = int(patternLengthValue)
  if length != csize_t(2 + textLength + patternLength): return -1
  for index in 0 ..< textLength + patternLength:
    if inputValues[2 + index] < 0 or inputValues[2 + index] > 127: return -1
  if patternLength == 0: return 0
  if patternLength > textLength: return -1

  let patternStart = 2 + textLength
  var lastOccurrence: array[128, int]
  for value in 0 ..< 128: lastOccurrence[value] = -1
  for index in 0 ..< patternLength:
    lastOccurrence[int(inputValues[patternStart + index])] = index

  var alignment = 0
  while alignment <= textLength - patternLength:
    var patternIndex = patternLength
    while patternIndex > 0 and inputValues[patternStart + patternIndex - 1] == inputValues[2 + alignment + patternIndex - 1]:
      dec patternIndex
    if patternIndex == 0: return int64(alignment)
    let textByte = int(inputValues[2 + alignment + patternIndex - 1])
    var shift = patternIndex - 1 - lastOccurrence[textByte]
    if shift < 1: shift = 1
    alignment += shift
  -1
