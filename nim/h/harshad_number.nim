## Return 1 when n is divisible by its base-10 digit sum, else 0.
proc harshad_number*(n: int64): int64 {.cdecl, exportc: "harshad_number".} =
  if n <= 0 or n > 2147483647: return -1
  var remaining = n
  var digit_sum = 0'i64
  while remaining > 0:
    digit_sum += remaining mod 10
    remaining = remaining div 10
  if n mod digit_sum == 0: 1 else: 0
