## Iterative bitwise XOR for two nonnegative integers in the exact uint53 range.
const MaxUint53 = 9_007_199_254_740_991'i64

proc uint53_xor*(leftInput, rightInput: int64): int64 {.cdecl, exportc: "uint53_xor".} =
  if leftInput < 0 or leftInput > MaxUint53 or rightInput < 0 or rightInput > MaxUint53:
    return -1
  var left = leftInput
  var right = rightInput
  var result = 0'i64
  var bit = 1'i64
  while left != 0 and right != 0:
    let leftBit = left mod 2
    let rightBit = right mod 2
    result += ((leftBit + rightBit) mod 2) * bit
    left = (left - leftBit) div 2
    right = (right - rightBit) div 2
    bit *= 2
  result + (left + right) * bit
