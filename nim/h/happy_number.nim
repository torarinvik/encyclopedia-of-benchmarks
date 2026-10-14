## Standard happy-number test using Floyd cycle detection.
proc digitSquareSum(n: int64): int64 =
  var value = n
  var total: int64 = 0
  while value > 0:
    let digit = value mod 10
    total += digit * digit
    value = value div 10
  total

proc happy_number*(n: int64): int64 {.cdecl, exportc: "happy_number".} =
  if n <= 0: return -1
  var slow = digitSquareSum(n)
  var fast = digitSquareSum(digitSquareSum(n))
  while slow != fast:
    slow = digitSquareSum(slow)
    fast = digitSquareSum(digitSquareSum(fast))
  if slow == 1: 1 else: 0
