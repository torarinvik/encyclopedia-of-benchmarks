## Find the numerator of the closest bounded fraction below a reduced target.
const MaxDenominator = 1_000_000'i64

proc gcdPositive(leftValue, rightValue: int64): int64 =
  var left = leftValue
  var right = rightValue
  while right != 0:
    let remainder = left mod right
    left = right
    right = remainder
  left

proc problem71*(input: ptr UncheckedArray[int64], length: csize_t): int64 {.cdecl, exportc: "problem71".} =
  if input == nil or length != 3: return -1
  let targetNumerator = input[0]
  let targetDenominator = input[1]
  let limit = input[2]
  if targetNumerator < 1 or targetDenominator <= targetNumerator or
      targetDenominator > MaxDenominator or limit < 1 or limit > MaxDenominator or
      gcdPositive(targetNumerator, targetDenominator) != 1:
    return -1

  var bestNumerator = 0'i64
  var bestDenominator = 1'i64
  for currentDenominator in 1'i64 .. limit:
    var currentNumerator = currentDenominator * targetNumerator div targetDenominator
    if currentDenominator mod targetDenominator == 0: dec currentNumerator
    if currentNumerator * bestDenominator > currentDenominator * bestNumerator:
      bestNumerator = currentNumerator
      bestDenominator = currentDenominator
  bestNumerator
