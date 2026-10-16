const MaxTextLength = 128
const MaxPatternLength = 64

proc substring_search*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "substring_search".} =
  if values.isNil or length < 2 or length > 195: return -2
  let textLength = values[0]
  let patternLength = values[1]
  if textLength < 0 or textLength > MaxTextLength or patternLength < 0 or patternLength > MaxPatternLength:
    return -2
  if length != csize_t(2 + textLength + patternLength): return -2
  let textStart = 2
  let patternStart = textStart + int(textLength)
  for i in textStart ..< int(length):
    if values[i] < 1 or values[i] > 127: return -2
  var textIndex = 0
  var patternIndex = 0
  var matchStart = -1'i64
  while textIndex < int(textLength):
    let expected = if patternIndex < int(patternLength): values[patternStart + patternIndex] else: 0
    if values[textStart + textIndex] == expected:
      if matchStart == -1: matchStart = int64(textIndex)
      inc patternIndex
      if patternIndex == int(patternLength): return matchStart
      inc textIndex
    else:
      matchStart = -1
      patternIndex = 0
      inc textIndex
  -1'i64
