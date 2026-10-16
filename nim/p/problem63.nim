proc problem63*(maxBase, maxPower: int64): int64 {.cdecl, exportc: "problem63".} =
  let baseLimit = min(maxBase, 10'i64)
  let powerLimit = min(maxPower, 22'i64)
  var count = 0'i64
  var base = 1'i64
  while base < baseLimit:
    var power = 1'i64
    while power < powerLimit:
      var digits: array[32, int]
      digits[0] = 1
      var length = 1
      for exponent in 0'i64..<power:
        var carry = 0
        for index in 0..<length:
          let value = digits[index] * int(base) + carry
          digits[index] = value mod 10
          carry = value div 10
        while carry > 0:
          digits[length] = carry mod 10
          inc length
          carry = carry div 10
      if int64(length) == power: inc count
      inc power
    inc base
  count
