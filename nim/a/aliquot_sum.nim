## Scan proper divisors under the shared signed 64-bit contract.
proc aliquot_sum*(n: int64): int64 {.cdecl, exportc: "aliquot_sum".} =
  if n < 0:
    return -1
  var total = 0'i64
  var divisor = 1'i64
  while divisor <= n div 2:
    if n mod divisor == 0:
      if total > high(int64) - divisor:
        return -1
      total += divisor
    inc divisor
  return total
