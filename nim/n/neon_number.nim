## A neon number equals the sum of the digits of its square.
proc neon_number*(number: int64): int64 {.cdecl, exportc: "neon_number".} =
  if number < 0: return 0
  if number > 3_000_000_000'i64: return -1
  var square = number * number
  var digitSum = 0'i64
  while square > 0:
    digitSum += square mod 10
    square = square div 10
  if digitSum == number: 1 else: 0
