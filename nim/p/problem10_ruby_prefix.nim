# Ruby Project Euler 10's strict cumulative-prime prefix.
proc isPrimeValue(number: int64): bool =
  if number > 1 and number < 4: return true
  if number < 2 or number mod 2 == 0 or number mod 3 == 0: return false
  var divisor = 5'i64
  while divisor * divisor <= number:
    if number mod divisor == 0 or number mod (divisor + 2) == 0: return false
    divisor += 6
  true

proc problem10_ruby_prefix*(maxTotal: int64): int64 {.cdecl, exportc: "problem10_ruby_prefix".} =
  if maxTotal < 0 or maxTotal > 2_000_000: return -1
  var sum = 1'i64
  var value = 1'i64
  var number = 2'i64
  while number < maxTotal and value < maxTotal:
    if isPrimeValue(number):
      value += number
      if value < maxTotal: sum = value
    number += 1
  sum
