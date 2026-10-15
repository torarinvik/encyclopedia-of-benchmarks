type I64Input = ptr UncheckedArray[int64]

func hexNibble(value: int64): int64 =
  if value >= 48 and value <= 57: return value - 48
  if value >= 65 and value <= 70: return value - 65 + 10
  if value >= 97 and value <= 102: return value - 97 + 10
  -1

proc hex_to_rgb*(input: I64Input, length: csize_t): int64 {.cdecl, exportc: "hex_to_rgb".} =
  if input == nil or length != 6: return -1
  var packedRgb = 0'i64
  for index in 0 ..< 6:
    let nibble = hexNibble(input[index])
    if nibble < 0: return -1
    packedRgb = (packedRgb shl 4) or nibble
  packedRgb
