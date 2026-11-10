## Check whether n equals the sum of its positive proper divisors.
proc perfect_number*(n: int64): int64 {.cdecl, exportc: "perfect_number".} =
  if n <= 1: return 0
  if n > 1_000_000_000_000'i64: return -1

  let number = uint64(n)
  let stride = 1'u64 + (number and 1'u64)
  var divisor_sum = 1'u64
  if stride == 1 and number >= 4:
    let half = number shr 1
    divisor_sum = if half == 2: 3'u64 else: 3 + half
  var factor = 3'u64
  while true:
    let partner = number div factor
    if factor > partner: break
    if partner * factor == number:
      divisor_sum += factor
      if partner != factor: divisor_sum += partner
      if divisor_sum > number: return 0
    factor += stride
  return (if divisor_sum == number: 1'i64 else: 0'i64)
