## Check whether n equals the sum of its positive proper divisors.
proc perfect_number*(n: int64): int64 {.cdecl, exportc: "perfect_number".} =
  if n <= 1: return 0
  if n > 1_000_000_000_000'i64: return -1

  var divisor_sum = 1'i64
  var factor = 2'i64
  while factor <= n div factor:
    if n mod factor == 0:
      divisor_sum += factor
      let partner = n div factor
      if partner != factor: divisor_sum += partner
      if divisor_sum > n: return 0
    factor += 1
  return (if divisor_sum == n: 1'i64 else: 0'i64)
