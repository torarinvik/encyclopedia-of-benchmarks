## Match n against the signed sum of the cubes of its decimal digits.
proc armstrong_digit_cubes*(n: int64): int64
    {.cdecl, exportc: "armstrong_digit_cubes".} =
  if n < -2_147_483_648'i64 or n > 2_147_483_647'i64: return -1
  let original = n
  var magnitude = n
  if magnitude < 0: magnitude = -magnitude
  var sum = 0'i64
  while magnitude > 0:
    let digit = magnitude mod 10
    sum += digit * digit * digit
    magnitude = magnitude div 10
  if original < 0: sum = -sum
  if sum == original: 1 else: 0
