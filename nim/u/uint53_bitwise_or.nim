## Bitwise inclusive OR over the Lua uint53 domain.
proc uint53_bitwise_or*(left, right: uint64): int64 {.cdecl, exportc: "uint53_bitwise_or".} =
  const maxUint53 = 9_007_199_254_740_991'u64
  if left > maxUint53 or right > maxUint53: return -1
  var n = left
  var m = right
  var accumulated = 0'u64
  var bit = 1'u64
  while n != 0 and m != 0:
    let nBit = n mod 2
    let mBit = m mod 2
    accumulated += (1'u64 - (1'u64 - nBit) * (1'u64 - mBit)) * bit
    n = (n - nBit) div 2
    m = (m - mBit) div 2
    bit *= 2
  int64(accumulated + (n + m) * bit)
