proc abundant_number*(n: int64): int64 {.cdecl, exportc: "abundant_number".} =
  if n < 1 or n > 1_000_000_000:
    return -1
  if n == 1:
    return 0
  var sum = 1'i64
  var divisor = 2'i64
  while divisor <= n div divisor:
    if n mod divisor == 0:
      sum += divisor
      let partner = n div divisor
      if partner != divisor:
        sum += partner
      if sum > n:
        return 1
    inc divisor
  return 0
