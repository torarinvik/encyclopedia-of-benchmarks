import std/math

const MaxStringLength = 64
const MaxInputLength = 132
const AlphabetSize = 95
const InvalidResult = -1.0e300

proc cosine_similarity*(input: ptr UncheckedArray[int64], length: csize_t): float64
    {.cdecl, exportc: "cosine_similarity".} =
  if input.isNil or length < 2 or length > MaxInputLength: return InvalidResult
  let leftLengthValue = input[0]
  let rightLengthValue = input[1]
  if leftLengthValue < 0 or leftLengthValue > MaxStringLength or rightLengthValue < 0 or rightLengthValue > MaxStringLength:
    return InvalidResult
  let leftLength = int(leftLengthValue)
  let rightLength = int(rightLengthValue)
  if int(length) != 2 + leftLength + rightLength: return InvalidResult

  var leftCounts: array[AlphabetSize, uint64]
  var rightCounts: array[AlphabetSize, uint64]
  for i in 0 ..< leftLength:
    var value = input[2 + i]
    if value < 32 or value > 126: return InvalidResult
    if value >= 65 and value <= 90: value += 32
    inc leftCounts[int(value - 32)]
  for i in 0 ..< rightLength:
    var value = input[2 + leftLength + i]
    if value < 32 or value > 126: return InvalidResult
    if value >= 65 and value <= 90: value += 32
    inc rightCounts[int(value - 32)]

  var dotProduct = 0.0
  var leftMagnitudeSquared = 0.0
  var rightMagnitudeSquared = 0.0
  for i in 0 ..< AlphabetSize:
    let left = float64(leftCounts[i])
    let right = float64(rightCounts[i])
    dotProduct += left * right
    leftMagnitudeSquared += left * left
    rightMagnitudeSquared += right * right
  if leftMagnitudeSquared <= 0.0 or rightMagnitudeSquared <= 0.0: return 0.0
  dotProduct / (sqrt(leftMagnitudeSquared) * sqrt(rightMagnitudeSquared))
