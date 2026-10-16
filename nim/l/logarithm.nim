proc logarithm*(input: int64): int64 {.cdecl, exportc: "logarithm".} =
  if input < 1 or input > 4_294_967_295'i64: return -1
  var value = input
  var result = 0'i64
  if (value and 0xFFFF0000'i64) != 0:
    value = value shr 16
    result += 16
  if (value and 0x0000FF00'i64) != 0:
    value = value shr 8
    result += 8
  if (value and 0x000000F0'i64) != 0:
    value = value shr 4
    result += 4
  if (value and 0x0000000C'i64) != 0:
    value = value shr 2
    result += 2
  if (value and 0x00000002'i64) != 0:
    result += 1
  result
