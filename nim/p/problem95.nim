const MaxLimit = 1_000_000
const Mark = 0x80000000'u32
const Mask = 0x7fffffff'u32
proc problem95*(limit: int64): int64 {.cdecl, exportc: "problem95".} =
  if limit < 1 or limit > MaxLimit: return -1
  let n = int(limit)
  var sums = newSeq[uint32](n + 1)
  for divisor in 1 .. n div 2:
    for multiple in countup(2 * divisor, n, divisor): sums[multiple] += divisor.uint32
  var bestLength = 0
  var answer = 0'i64
  for start in 2 .. n:
    var current = sums[start]
    var length = 1
    sums[start] = sums[start] or Mark
    while current > 1 and current.int <= n and (sums[current.int] and Mark) == 0:
      sums[current.int] = sums[current.int] or Mark
      current = sums[current.int] and Mask
      inc length
    if current.int == start and length > bestLength: bestLength = length; answer = start.int64
    current = start.uint32
    for _ in 0 ..< length:
      let next = sums[current.int] and Mask
      sums[current.int] = next
      current = next
  answer
