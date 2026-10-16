## Return whether a pattern occurs using Knuth-Morris-Pratt matching.
proc knuth_morris_pratt_contains*(packed: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "knuth_morris_pratt_contains".} =
  if packed.isNil or length < 2 or length > 8194: return -1
  let textLengthValue = packed[0]
  let patternLengthValue = packed[1]
  if textLengthValue < 0 or textLengthValue > 4096 or patternLengthValue < 0 or patternLengthValue > 4096: return -1
  let textLength = int(textLengthValue)
  let patternLength = int(patternLengthValue)
  if length != csize_t(2 + textLength + patternLength): return -1
  for index in 0 ..< textLength + patternLength:
    if packed[2 + index] < 0 or packed[2 + index] > 127: return -1
  if patternLength == 0: return 0

  let patternStart = 2 + textLength
  var prefix: array[4096, int]
  var index = 1
  var matched = 0
  while index < patternLength:
    while matched > 0 and packed[patternStart + index] != packed[patternStart + matched]:
      matched = prefix[matched - 1]
    if packed[patternStart + index] == packed[patternStart + matched]: inc matched
    prefix[index] = matched
    inc index

  index = 0
  matched = 0
  while index < textLength:
    while matched > 0 and packed[2 + index] != packed[patternStart + matched]:
      matched = prefix[matched - 1]
    if packed[2 + index] == packed[patternStart + matched]: inc matched
    if matched == patternLength: return 1
    inc index
  0
