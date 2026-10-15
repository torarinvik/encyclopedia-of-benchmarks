proc xs3_conversion*(packed: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "xs3_conversion".} =
  if length != 2:
    return -1
  let direction = packed[0]
  var value = packed[1]
  if direction == 0:
    if value < 0 or value > 2147483647'i64:
      return -1
    var decoded: int64 = 0
    var multiplier: int64 = 1
    while value > 0:
      let nibble = value and 15
      if nibble < 3 or nibble > 12:
        return -1
      decoded += (nibble - 3) * multiplier
      multiplier *= 10
      value = value shr 4
    return decoded
  if direction == 1:
    if value < 0 or value > 9999999:
      return -1
    var encoded: int64 = 0
    var shift = 0
    while value > 0:
      let digit = value mod 10 + 3
      encoded = encoded or (digit shl (shift * 4))
      value = value div 10
      inc shift
    return encoded
  -1
