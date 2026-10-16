proc problem301*(exponent: int64): int64 {.cdecl, exportc: "problem301".} =
  if exponent < 0 or exponent > 30: return -1
  var previous = 0'i64
  var current = 1'i64
  for _ in 0'i64..<(exponent + 2):
    let next = previous + current
    previous = current
    current = next
  previous - (exponent mod 2)
