proc isPalindrome(value: int64): bool =
  var remaining = value
  var reversed = 0'i64
  while remaining > 0:
    reversed = reversed * 10 + remaining mod 10
    remaining = remaining div 10
  reversed == value

proc problem4*(digits: int64): int64 {.cdecl, exportc: "problem4".} =
  if digits < 1 or digits > 3: return -1
  let minimum = if digits == 1: 1'i64 elif digits == 2: 10'i64 else: 100'i64
  let maximum = if digits == 1: 9'i64 elif digits == 2: 99'i64 else: 999'i64
  var largest = 0'i64
  var first = maximum
  while first >= minimum and first * maximum > largest:
    var second = maximum
    while second >= first and first * second > largest:
      let product = first * second
      if isPalindrome(product): largest = product
      dec second
    dec first
  largest
