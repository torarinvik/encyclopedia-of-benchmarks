type I64Input = ptr UncheckedArray[int64]

proc rgbhex*(input: I64Input, length: csize_t): int64 {.cdecl, exportc: "rgbhex".} =
  if input == nil or length != 4: return -1
  let op = input[0]
  let x = input[1]
  let y = input[2]
  let z = input[3]
  if op == 0:
    if x < 0 or x > 4294967295'i64 or y != 0 or z != 0: return -1
    return x and 0x00ffffff
  if op == 1:
    if x < 0 or x > 255 or y < 0 or y > 255 or z < 0 or z > 255: return -1
    return (x shl 16) or (y shl 8) or z
  -1
