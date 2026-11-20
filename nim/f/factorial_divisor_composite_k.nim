proc factorialDivisorCompositeKValuation(n, prime: uint64): uint64 =
  var quotient = n
  var total = 0'u64
  while quotient != 0:
    quotient = quotient div prime
    total += quotient
  return total

proc factorial_divisor_composite_k*(n, k: uint64): int64 {.cdecl, exportc: "factorial_divisor_composite_k".} =
  if n > 1_000_000_000_000'u64 or k < 4'u64 or k > 1_000_000'u64:
    return -1

  var remaining = k
  var divisor = 2'u64
  var answer = n
  var composite = false
  while divisor <= remaining div divisor:
    if remaining mod divisor == 0:
      composite = true
      var exponent = 0'u64
      while remaining mod divisor == 0:
        remaining = remaining div divisor
        exponent += 1
      let candidate = factorialDivisorCompositeKValuation(n, divisor) div exponent
      if candidate < answer:
        answer = candidate
    divisor += 1

  if not composite:
    return -1
  if remaining > 1:
    let candidate = factorialDivisorCompositeKValuation(n, remaining)
    if candidate < answer:
      answer = candidate
  return int64(answer)
