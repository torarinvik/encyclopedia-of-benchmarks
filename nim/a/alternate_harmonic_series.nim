## Check alternating signs and an arithmetic progression of reciprocal magnitudes.
const MaxCount = 1000

proc alternate_harmonic_series*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "alternate_harmonic_series".} =
  if length < 1 or length > csize_t(1 + 2 * MaxCount) or values == nil: return -1
  let countValue = values[0]
  if countValue < 1 or countValue > MaxCount: return -1
  let count = int(countValue)
  if length != csize_t(1 + 2 * count): return -1

  for index in 0 ..< count:
    let numerator = values[1 + 2 * index]
    let denominator = values[2 + 2 * index]
    if numerator == 0 or numerator < -1000 or numerator > 1000 or denominator < 1 or denominator > 1000:
      return -1
  for index in 1 ..< count:
    if (values[1 + 2 * index] < 0) == (values[1 + 2 * (index - 1)] < 0): return 0
  if count < 3: return 1

  var firstNumerator = values[1]
  if firstNumerator < 0: firstNumerator = -firstNumerator
  var secondNumerator = values[3]
  if secondNumerator < 0: secondNumerator = -secondNumerator
  let baseDifferenceNumerator = values[4] * firstNumerator - values[2] * secondNumerator
  let baseDifferenceDenominator = firstNumerator * secondNumerator

  for index in 2 ..< count:
    var previousNumerator = values[1 + 2 * (index - 1)]
    if previousNumerator < 0: previousNumerator = -previousNumerator
    var currentNumerator = values[1 + 2 * index]
    if currentNumerator < 0: currentNumerator = -currentNumerator
    let previousDenominator = values[2 + 2 * (index - 1)]
    let currentDenominator = values[2 + 2 * index]
    let differenceNumerator = currentDenominator * previousNumerator - previousDenominator * currentNumerator
    let differenceDenominator = previousNumerator * currentNumerator
    if differenceNumerator * baseDifferenceDenominator != baseDifferenceNumerator * differenceDenominator:
      return 0
  1
