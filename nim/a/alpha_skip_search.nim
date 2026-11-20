const MaxTextLength = 4096
const MaxPatternLength = 128
const MaxBuckets = 64
const MaxInputLength = 4227

proc alpha_skip_search*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "alpha_skip_search".} =
  if input == nil or length < 2 or length > csize_t(MaxInputLength): return -1
  let textLength64 = input[0]
  let patternLength64 = input[1]
  if textLength64 < 0 or textLength64 > int64(MaxTextLength) or
      patternLength64 < 1 or patternLength64 > int64(MaxPatternLength): return -1
  let textLength = int(textLength64)
  let patternLength = int(patternLength64)
  if length != csize_t(2 + textLength + patternLength): return -1

  var text: array[MaxTextLength, uint8]
  var pattern: array[MaxPatternLength, uint8]
  for i in 0 ..< textLength:
    let symbol = input[2 + i]
    if symbol < 0 or symbol > 3: return -1
    text[i] = uint8(symbol)
  let patternOffset = 2 + textLength
  for i in 0 ..< patternLength:
    let symbol = input[patternOffset + i]
    if symbol < 0 or symbol > 3: return -1
    pattern[i] = uint8(symbol)

  var factorLength = 1
  var bucketCount = 4
  while bucketCount * 4 <= patternLength:
    bucketCount *= 4
    inc factorLength
  let factorCount = patternLength - factorLength + 1
  var factorPower = 1
  for i in 1 ..< factorLength: factorPower *= 4
  var heads: array[MaxBuckets, int]
  for i in 0 ..< MaxBuckets: heads[i] = -1
  var nextPosition: array[MaxPatternLength, int]
  var code = 0
  for i in 0 ..< factorLength: code = code * 4 + int(pattern[i])
  for position in 0 ..< factorCount:
    if position > 0:
      code = (code - int(pattern[position - 1]) * factorPower) * 4 + int(pattern[position + factorLength - 1])
    nextPosition[position] = heads[code]
    heads[code] = position

  if textLength < patternLength: return 0
  let shift = patternLength - factorLength + 1
  var matchCount = 0'i64
  var offsetSum = 0'i64
  var offsetXor = 0'i64
  var sampleStart = 0
  while sampleStart <= textLength - factorLength:
    var textCode = 0
    for offset in 0 ..< factorLength:
      textCode = textCode * 4 + int(text[sampleStart + offset])
    var patternPosition = heads[textCode]
    while patternPosition >= 0:
      let candidate = sampleStart - patternPosition
      if candidate >= 0 and candidate <= textLength - patternLength:
        var matches = true
        for offset in 0 ..< patternLength:
          if text[candidate + offset] != pattern[offset]:
            matches = false
            break
        if matches:
          inc matchCount
          offsetSum += int64(candidate)
          offsetXor = offsetXor xor int64(candidate)
      patternPosition = nextPosition[patternPosition]
    sampleStart += shift
  (matchCount shl 36) or (offsetSum shl 12) or offsetXor
