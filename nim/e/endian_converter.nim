const InvalidResult = -2_147_483_649'i64

## Reverse the byte order of a signed 32-bit integer.
proc endian_converter*(value: int64): int64 {.cdecl, exportc: "endian_converter".} =
  if value < int64(low(int32)) or value > int64(high(int32)): return InvalidResult
  let bits = value and 0xFFFF_FFFF'i64
  let reversed = ((bits and 0xFF'i64) shl 24) or ((bits and 0xFF00'i64) shl 8) or
                 ((bits and 0xFF0000'i64) shr 8) or ((bits and 0xFF000000'i64) shr 24)
  if reversed >= 2_147_483_648'i64: reversed - 4_294_967_296'i64 else: reversed
