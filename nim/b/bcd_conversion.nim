const InvalidResult = -1'i64

proc bcd_conversion*(decimal: int64): int64 {.cdecl, exportc: "bcd_conversion".} =
  if decimal < 0 or decimal > 9999: return InvalidResult
  var value = decimal
  var bcd = 0'i64
  var shift = 0'i64
  while value > 0:
    let digit = value mod 10
    bcd = bcd or (digit shl (shift * 4))
    value = value div 10
    inc shift
  bcd
