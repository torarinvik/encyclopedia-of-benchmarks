## XOR two values in the bounded unsigned 53-bit domain.
const MaxUint53 = 9_007_199_254_740_991'u64
const InvalidResult = -1'i64

proc uint53_bitwise_xor*(n, m: uint64): int64
    {.cdecl, exportc: "uint53_bitwise_xor".} =
  if n > MaxUint53 or m > MaxUint53: return InvalidResult

  var currentN = n
  var currentM = m
  var result: uint64 = 0
  var bit: uint64 = 1
  while currentN != 0 and currentM != 0:
    let nBit = currentN mod 2
    let mBit = currentM mod 2
    result += ((nBit + mBit) mod 2) * bit
    currentN = (currentN - nBit) div 2
    currentM = (currentM - mBit) div 2
    bit *= 2
  int64(result + (currentN + currentM) * bit)
