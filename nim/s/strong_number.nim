## Check whether the sum of the decimal digits' factorials equals the input.
proc strong_number*(number: int64): int64 {.cdecl, exportc: "strong_number".} =
  if number < int64(low(int32)) or number > int64(high(int32)): return -1
  if number < 0: return 0
  var remaining = number
  var sum = 0'i64
  if remaining == 0: sum = 1
  while remaining > 0:
    let digit = remaining mod 10
    var factorial = 1'i64
    for factor in 2'i64 .. digit: factorial *= factor
    sum += factorial
    remaining = remaining div 10
  if sum == number: 1 else: 0
