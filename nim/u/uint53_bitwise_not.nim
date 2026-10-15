## Complement every bit in the fixed-width unsigned 53-bit domain.
const MaxUint53 = 9_007_199_254_740_991'i64
const TwoTo53 = 9_007_199_254_740_992'i64

proc uint53_bitwise_not*(n: int64): int64 {.cdecl, exportc: "uint53_bitwise_not".} =
  if n < 0 or n > MaxUint53: return -1

  var current = n
  var result: int64 = 0
  var bit: int64 = 1
  while current >= 255:
    let byte = current mod 256
    result += (255 - byte) * bit
    current = (current - byte) div 256
    bit *= 256
  while current != 0:
    let nBit = current mod 2
    result += (1 - nBit) * bit
    current = (current - nBit) div 2
    bit *= 2

  TwoTo53 - bit + result
