## Return the first ASCII byte match using bad-character and good-suffix shifts.
proc boyer_moore*(inputValues: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "boyer_moore".} =
  if inputValues == nil or length < 2 or length > 8194: return -1
  if inputValues[0] < 0 or inputValues[0] > 4096 or inputValues[1] < 0 or inputValues[1] > 4096: return -1
  let textLength = int(inputValues[0])
  let patternLength = int(inputValues[1])
  if length != csize_t(2 + textLength + patternLength): return -1
  for index in 0 ..< textLength + patternLength:
    if inputValues[2 + index] < 0 or inputValues[2 + index] > 126: return -1
  if patternLength == 0: return 0
  if patternLength > textLength: return -1

  let patternStart = 2 + textLength
  var lastOccurrence: array[127, int]
  for byte in 0 ..< 127: lastOccurrence[byte] = -1
  for index in 0 ..< patternLength:
    lastOccurrence[int(inputValues[patternStart + index])] = index

  var goodSuffix: array[4097, int]
  var borderPosition: array[4097, int]
  var i = patternLength
  var j = patternLength + 1
  borderPosition[i] = j
  while i > 0:
    while j <= patternLength and inputValues[patternStart + i - 1] != inputValues[patternStart + j - 1]:
      if goodSuffix[j] == 0: goodSuffix[j] = j - i
      j = borderPosition[j]
    dec i
    dec j
    borderPosition[i] = j
  j = borderPosition[0]
  for i in 0 .. patternLength:
    if goodSuffix[i] == 0: goodSuffix[i] = j
    if i == j: j = borderPosition[j]

  var alignment = 0
  while alignment <= textLength - patternLength:
    var patternIndex = patternLength
    while patternIndex > 0 and
        inputValues[patternStart + patternIndex - 1] == inputValues[2 + alignment + patternIndex - 1]:
      dec patternIndex
    if patternIndex == 0: return int64(alignment)
    let textByte = int(inputValues[2 + alignment + patternIndex - 1])
    var badShift = patternIndex - 1 - lastOccurrence[textByte]
    if badShift < 1: badShift = 1
    alignment += max(goodSuffix[patternIndex], badShift)
  -1
