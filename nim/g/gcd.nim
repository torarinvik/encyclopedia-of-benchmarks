## Portable iterative Euclidean GCD; workload values fit signed 64-bit.
proc gcd*(left, right: uint64): int64 {.cdecl, exportc: "gcd".} =
  var dividend = left
  var divisor = right
  while divisor != 0:
    let remainder = dividend mod divisor
    dividend = divisor
    divisor = remainder
  return int64(dividend)
