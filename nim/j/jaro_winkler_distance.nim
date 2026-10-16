const MaxStringLength = 32
const MaxInputLength = 2 + 2 * MaxStringLength
const Scale = 1_000_000_000'i64

proc jaro_winkler_distance*(input: ptr UncheckedArray[int64], length: csize_t): int64 {.cdecl, exportc: "jaro_winkler_distance".} =
  if input.isNil or length < csize_t(2) or length > csize_t(MaxInputLength): return -1

  let firstLengthValue = input[0]
  if firstLengthValue < 0 or firstLengthValue > int64(MaxStringLength): return -1
  let firstLength = int(firstLengthValue)
  let secondLengthIndex = 1 + firstLength
  if csize_t(secondLengthIndex) >= length: return -1
  let secondLengthValue = input[secondLengthIndex]
  if secondLengthValue < 0 or secondLengthValue > int64(MaxStringLength) or
      firstLengthValue < secondLengthValue or
      length != csize_t(secondLengthIndex + 1) + csize_t(secondLengthValue): return -1
  let secondLength = int(secondLengthValue)

  for i in 0 ..< firstLength:
    let value = input[1 + i]
    if value < 0 or value > 127: return -1
  for i in 0 ..< secondLength:
    let value = input[secondLengthIndex + 1 + i]
    if value < 0 or value > 127: return -1

  if firstLength == secondLength:
    var equal = true
    for i in 0 ..< firstLength:
      if input[1 + i] != input[secondLengthIndex + 1 + i]:
        equal = false
        break
    if equal: return 0
  if secondLength == 0: return Scale

  let half = firstLength div 2
  let radius = if half > 0: half - 1 else: 0
  var firstMatched: array[MaxStringLength, bool]
  var secondMatched: array[MaxStringLength, bool]
  var matchCount = 0
  for i in 0 ..< firstLength:
    let start = max(i - radius, 0)
    let ending = min(i + radius, secondLength - 1)
    if start > ending: continue
    for j in start .. ending:
      if input[1 + i] == input[secondLengthIndex + 1 + j] and not secondMatched[j]:
        firstMatched[i] = true
        secondMatched[j] = true
        inc matchCount
        break
  if matchCount == 0: return Scale

  var secondIndex = 0
  var mismatchedPairs = 0
  for i in 0 ..< firstLength:
    if not firstMatched[i]: continue
    while secondIndex < secondLength and not secondMatched[secondIndex]: inc secondIndex
    if secondIndex == secondLength: return -1
    if input[1 + i] != input[secondLengthIndex + 1 + secondIndex]: inc mismatchedPairs
    inc secondIndex

  let matches = int64(matchCount)
  let firstSize = int64(firstLength)
  let secondSize = int64(secondLength)
  let transpositions = int64(mismatchedPairs div 2)
  let jaroNumerator = matches * matches * secondSize + matches * matches * firstSize +
    (matches - transpositions) * firstSize * secondSize
  let jaroDenominator = 3'i64 * firstSize * secondSize * matches

  var prefixLength = 0
  let prefixLimit = min(secondLength, 4)
  while prefixLength < prefixLimit and input[1 + prefixLength] == input[secondLengthIndex + 1 + prefixLength]:
    inc prefixLength
  let denominator = 10'i64 * jaroDenominator
  let numerator = int64(10 - prefixLength) * (jaroDenominator - jaroNumerator)
  (numerator * Scale + denominator div 2) div denominator
