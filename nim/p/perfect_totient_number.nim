## Decide whether the iterated Euler-totient chain sums to n.
proc perfect_totient_number*(n: int64): int64 {.cdecl, exportc: "perfect_totient_number".} =
  if n < 3 or n > 65535: return -1
  var value = n
  var total = 0'i64
  while value > 1:
    var phi_value = value
    var remaining = value
    var factor = 2'i64
    while factor <= remaining div factor:
      if remaining mod factor == 0:
        while remaining mod factor == 0: remaining = remaining div factor
        phi_value -= phi_value div factor
      inc factor
    if remaining > 1: phi_value -= phi_value div remaining
    value = phi_value
    total += value
  if total == n: 1 else: 0
