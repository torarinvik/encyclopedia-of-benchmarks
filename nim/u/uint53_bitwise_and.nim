proc uint53_bitwise_and*(n, m: int64): int64 {.cdecl, exportc: "uint53_bitwise_and".} =
  const maxUint53 = 9_007_199_254_740_991'i64
  if n < 0 or m < 0 or n > maxUint53 or m > maxUint53: return -1
  var left = n
  var right = m
  var result: int64 = 0
  var bit: int64 = 1
  while left != 0 and right != 0:
    let leftBit = left mod 2
    let rightBit = right mod 2
    result += leftBit * rightBit * bit
    left = (left - leftBit) div 2
    right = (right - rightBit) div 2
    bit *= 2
  result
