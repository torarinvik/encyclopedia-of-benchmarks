const MaxInputLength = 258
const MaxSearchLength = 128
const MaxPatternLength = 128

proc minimumWindowSubsequence*(input: ptr UncheckedArray[int64], length: csize_t,
        output: ptr UncheckedArray[uint8], capacity: csize_t): int64 {.cdecl, exportc: "minimum_window_subsequence".} =
  if input.isNil or length < 3 or length > MaxInputLength: return -1
  if input[0] < 0 or input[0] > MaxSearchLength: return -1
  let searchLength = int(input[0])
  let patternLengthIndex = searchLength + 1
  if int(length) <= patternLengthIndex: return -1
  let patternLengthValue = input[patternLengthIndex]
  if patternLengthValue < 1 or patternLengthValue > MaxPatternLength: return -1
  let patternLength = int(patternLengthValue)
  if int(length) != searchLength + patternLength + 2: return -1
  for i in 0..<searchLength:
    if input[i + 1] < 0 or input[i + 1] > 127: return -1
  for j in 0..<patternLength:
    if input[searchLength + 2 + j] < 0 or input[searchLength + 2 + j] > 127: return -1

  var latestStart: array[MaxPatternLength, int8]
  for j in 0..<patternLength: latestStart[j] = -1
  var bestStart = -1
  var bestLength = searchLength + 1
  for end in 0..<searchLength:
    let byte = input[end + 1]
    for offset in 0..<patternLength:
      let patternIndex = patternLength - 1 - offset
      if byte != input[searchLength + 2 + patternIndex]: continue
      let candidate = if patternIndex == 0: end else: int(latestStart[patternIndex - 1])
      if candidate >= 0 and candidate > int(latestStart[patternIndex]):
        latestStart[patternIndex] = int8(candidate)
    if byte == input[searchLength + 2 + patternLength - 1] and latestStart[patternLength - 1] >= 0:
      let start = int(latestStart[patternLength - 1])
      let windowLength = end - start + 1
      if windowLength < bestLength or (windowLength == bestLength and (bestStart < 0 or start < bestStart)):
        bestStart = start
        bestLength = windowLength
  if bestStart < 0: return 0
  if bestLength > int(capacity) or (bestLength > 0 and output.isNil): return -2
  for i in 0..<bestLength: output[i] = uint8(input[bestStart + 1 + i])
  int64(bestLength)
