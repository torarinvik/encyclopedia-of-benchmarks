const MaxDenominator = 12_000

proc gcd(leftValue, rightValue: int): int =
  var left = leftValue
  var right = rightValue
  while right != 0:
    let remainder = left mod right
    left = right
    right = remainder
  left

proc problem73*(maxDenominator: int64): int64 {.cdecl, exportc: "problem73".} =
  if maxDenominator < 0 or maxDenominator > MaxDenominator: return -1
  var count = 0'i64
  for denominator in 0 .. int(maxDenominator):
    var numeratorStart = denominator div 3 + 1
    var numeratorStep = 1
    if denominator mod 2 == 0:
      numeratorStart += 1 - numeratorStart mod 2
      numeratorStep = 2
    let numeratorEnd = (denominator + 1) div 2
    var numerator = numeratorStart
    while numerator < numeratorEnd:
      if gcd(numerator, denominator) == 1: inc count
      numerator += numeratorStep
  count
