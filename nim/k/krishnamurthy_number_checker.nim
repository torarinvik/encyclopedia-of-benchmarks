## Check whether n equals the sum of factorials of its decimal digits.
proc krishnamurthy_number_checker*(n: int64): int64 {.cdecl, exportc: "krishnamurthy_number_checker".} =
  if n < -2_147_483_648'i64 or n > 2_147_483_647'i64: return -1
  if n <= 0: return 0

  let original = n
  var remaining = n
  var sum = 0'i64
  while remaining != 0:
    let digit = remaining mod 10
    var factorial = 1'i64
    for factor in 2'i64 .. digit: factorial *= factor
    sum += factorial
    remaining = remaining div 10
  return (if sum == original: 1'i64 else: 0'i64)
