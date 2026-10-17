const MaxTextLength = 256
const MaxPatternLength = 64
const MaxInputLength = 322

proc kmp_all_occurrences*(values: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "kmp_all_occurrences".} =
  if values == nil or length < 2 or length > csize_t(MaxInputLength): return -1
  let textLengthValue = values[0]
  let patternLengthValue = values[1]
  if textLengthValue < 0 or textLengthValue > int64(MaxTextLength) or
      patternLengthValue < 1 or patternLengthValue > int64(MaxPatternLength): return -1
  let textLength = int(textLengthValue)
  let patternLength = int(patternLengthValue)
  if length != csize_t(2 + textLength + patternLength): return -1
  let patternOffset = 2 + textLength
  for i in 0 ..< textLength + patternLength:
    let value = values[2 + i]
    if value < 0 or value > 127: return -1

  var prefix: array[MaxPatternLength, int]
  for i in 1 ..< patternLength:
    var matched = prefix[i - 1]
    while matched > 0 and values[patternOffset + i] != values[patternOffset + matched]:
      matched = prefix[matched - 1]
    if values[patternOffset + i] == values[patternOffset + matched]: inc matched
    prefix[i] = matched

  var matches: array[MaxTextLength, int64]
  var matchCount = 0
  var matched = 0
  for i in 0 ..< textLength:
    while matched > 0 and values[2 + i] != values[patternOffset + matched]:
      matched = prefix[matched - 1]
    if values[2 + i] == values[patternOffset + matched]: inc matched
    if matched == patternLength:
      matches[matchCount] = int64(i + 1 - patternLength)
      inc matchCount
      matched = prefix[matched - 1]

  let outputBytes = matchCount * 8
  if output == nil or outputCapacity < csize_t(outputBytes): return -2
  for i in 0 ..< matchCount:
    let bits = uint64(matches[i])
    for byte in 0 ..< 8:
      output[i * 8 + byte] = uint8((bits shr (byte * 8)) and 255)
  int64(outputBytes)
