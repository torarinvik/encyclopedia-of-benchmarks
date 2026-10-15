## Check whether n equals the sum of each decimal digit raised to digit count.
proc narcissistic_number_checker*(n: int64): int64 {.cdecl, exportc: "narcissistic_number_checker".} =
  if n < -2_147_483_648'i64 or n > 999_999'i64: return -1

  let original = n
  var remaining = n
  var digits = 0'i64
  while remaining != 0:
    inc digits
    remaining = remaining div 10

  var sum = 0'i64
  remaining = n
  while remaining > 0:
    let digit = remaining mod 10
    var power = 1'i64
    for _ in 0'i64 ..< digits: power *= digit
    sum += power
    remaining = remaining div 10
  return (if sum == original: 1'i64 else: 0'i64)
