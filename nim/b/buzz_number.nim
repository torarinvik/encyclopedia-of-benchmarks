## Return 1 when n is divisible by seven or ends in decimal digit seven.
proc buzz_number*(n: int64): int64 {.cdecl, exportc: "buzz_number".} =
  if n mod 7 == 0:
    return 1
  if n >= 0 and n mod 10 == 7:
    return 1
  return 0
