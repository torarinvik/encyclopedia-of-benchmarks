## Exact decimal digit powers; 1 for Armstrong numbers and 0 otherwise.
proc armstrong_number*(n: int64): int64 {.cdecl, exportc: "armstrong_number".} =
  if n < 0:
    return 0
  if n == 0:
    return 1
  var digits = 0'i64
  var remaining = n
  while remaining > 0:
    inc digits
    remaining = remaining div 10
  var total = 0'i64
  remaining = n
  while remaining > 0:
    let digit = remaining mod 10
    var power = 1'i64
    var exponent = 0'i64
    while exponent < digits:
      power *= digit
      inc exponent
    if power > n - total:
      return 0
    total += power
    remaining = remaining div 10
  return (if total == n: 1'i64 else: 0'i64)
