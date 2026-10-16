proc problem16*(exponent: int64): int64 {.cdecl, exportc: "problem16".} =
  if exponent < 0 or exponent > 1000: return -1
  var digits: array[400, int64]
  digits[0] = 1
  var length = 1
  for _ in 0..<int(exponent):
    var carry = 0'i64
    for index in 0..<length:
      let value = digits[index] * 2 + carry
      digits[index] = value mod 10
      carry = value div 10
    while carry > 0:
      digits[length] = carry mod 10
      inc length
      carry = carry div 10
  var total = 0'i64
  for index in 0..<length: total += digits[index]
  total
