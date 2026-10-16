proc problem20*(n: int64): int64 {.cdecl, exportc: "problem20".} =
  if n < 0 or n > 100: return -1
  var digits: array[200, int64]
  digits[0] = 1
  var length = 1
  var factor = 2'i64
  while factor <= n:
    var carry = 0'i64
    for index in 0 ..< length:
      let value = digits[index] * factor + carry
      digits[index] = value mod 10
      carry = value div 10
    while carry > 0:
      digits[length] = carry mod 10
      length += 1
      carry = carry div 10
    factor += 1
  var sum = 0'i64
  for index in 0 ..< length: sum += digits[index]
  sum
