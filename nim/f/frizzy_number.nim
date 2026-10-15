## Sum base powers at the set-bit positions of n.
proc frizzy_number*(base, n: int64): int64 {.cdecl, exportc: "frizzy_number".} =
  if base < 2 or base > 10 or n < 0 or n > 1023: return -1
  var remaining = n
  var result = 0'i64
  var power = 1'i64
  while remaining > 0:
    if remaining mod 2 == 1: result += power
    remaining = remaining div 2
    if remaining > 0: power *= base
  result
