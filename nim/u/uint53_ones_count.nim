## Count set bits in the bounded unsigned 53-bit domain, byte by byte.
const MaxUint53 = 9_007_199_254_740_991'i64

proc countByteOnes(byte: int64): int64 =
  var current = byte
  var ones: int64 = 0
  while current > 0:
    let bit = current mod 2
    ones += bit
    current = (current - bit) div 2
  ones

proc uint53_ones_count*(n: int64): int64 {.cdecl, exportc: "uint53_ones_count".} =
  if n < 0 or n > MaxUint53: return -1

  var current = n
  var ones: int64 = 0
  while current != 0:
    let byte = current mod 256
    ones += countByteOnes(byte)
    current = (current - byte) div 256
  ones
