const MaxText = 512
const MinPattern = 2
const MaxPattern = 64
const MaxInput = 578

proc not_so_naive_search*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "not_so_naive_search".} =
  if values == nil or length < 2 or length > csize_t(MaxInput): return -2
  let rawText = values[0]
  let rawPattern = values[1]
  if rawText < 0 or rawText > int64(MaxText) or
      rawPattern < int64(MinPattern) or rawPattern > int64(MaxPattern):
    return -2
  let textLength = int(rawText)
  let patternLength = int(rawPattern)
  if length != csize_t(2 + textLength + patternLength): return -2
  let patternStart = 2 + textLength
  for i in 0 ..< textLength + patternLength:
    let byte = values[2 + i]
    if byte < 0 or byte > 127: return -2
  if patternLength > textLength: return -1

  let samePrefix = values[patternStart] == values[patternStart + 1]
  let mismatchShift = if samePrefix: 2 else: 1
  let postCheckShift = if samePrefix: 1 else: 2
  var position = 0
  let lastStart = textLength - patternLength
  while position <= lastStart:
    if values[patternStart + 1] != values[2 + position + 1]:
      position += mismatchShift
      continue
    var patternIndex = 2
    while patternIndex < patternLength and
        values[patternStart + patternIndex] == values[2 + position + patternIndex]:
      inc patternIndex
    if patternIndex == patternLength and values[patternStart] == values[2 + position]:
      return int64(position)
    position += postCheckShift
  -1
