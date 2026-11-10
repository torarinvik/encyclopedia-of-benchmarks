## Return the exact zero-based Catalan number through the signed 64-bit range.
proc catalan_number*(n: int64): int64 {.cdecl, exportc: "catalan_number".} =
  if n < 0 or n > 35: return -1

  var value = 1'i64
  var index = 1'i64
  while index <= n:
    var numerator = 4 * index - 2
    var denominator = index + 1
    let common: int64 = (if denominator mod 3 == 0: 3 else: 1) * (if denominator mod 2 == 0: 2 else: 1)
    numerator = numerator div common
    denominator = denominator div common
    value = (value div denominator) * numerator
    index += 1
  return value
