## Sum decimal digits raised to their one-based positions from the left.
proc disarium_number*(number: int64): int64 {.cdecl, exportc: "disarium_number".} =
  if number < 1 or number > 99_999_999: return -1
  var digits = number
  var count = 0'i64
  while digits > 0:
    inc count
    digits = digits div 10
  var position = count
  var remaining = number
  var sum = 0'i64
  while remaining > 0:
    let digit = remaining mod 10
    var power = 1'i64
    for exponent in 0 ..< int(position): power *= digit
    sum += power
    dec position
    remaining = remaining div 10
  if sum == number: 1 else: 0
