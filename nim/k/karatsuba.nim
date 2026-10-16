## Multiply bounded nonnegative operands with a three-product decimal split.
proc karatsubaProduct(left, right: int64): int64 =
  if left < 10 or right < 10: return left * right
  let largest = max(left, right)
  var digits = 1
  var remaining = largest
  while remaining >= 10:
    remaining = remaining div 10
    inc digits
  var split: int64 = 1
  for index in 0 ..< digits div 2: split *= 10
  let leftHigh = left div split
  let leftLow = left mod split
  let rightHigh = right div split
  let rightLow = right mod split
  let lowProduct = karatsubaProduct(leftLow, rightLow)
  let highProduct = karatsubaProduct(leftHigh, rightHigh)
  let sumProduct = karatsubaProduct(leftHigh + leftLow, rightHigh + rightLow)
  highProduct * split * split + (sumProduct - highProduct - lowProduct) * split + lowProduct

proc karatsuba*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "karatsuba".} =
  if input == nil or length != 2: return -1
  if input[0] < 0 or input[0] > 1_000_000 or input[1] < 0 or input[1] > 1_000_000: return -1
  karatsubaProduct(input[0], input[1])
