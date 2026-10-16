type I64Input = ptr UncheckedArray[int64]

proc truncDiv32(value: int32): int32 =
  if value < 0: return -((-value) div 32)
  value div 32

proc burkes_dithering*(input: I64Input, length: csize_t): int64
    {.cdecl, exportc: "burkes_dithering".} =
  if input == nil or length < 3 or length > 150: return -1
  if input[0] < 1 or input[0] > 7 or input[1] < 1 or input[1] > 254: return -1
  let side = int(input[0])
  let threshold = int32(input[1])
  if int(length) != 2 + 3 * side * side: return -1
  for index in 2 ..< int(length):
    if input[index] < 0 or input[index] > 255: return -1

  let stride = side + 4
  var errors: array[88, int32]
  var whitePixels = 0'u64
  for y in 0 ..< side:
    for x in 0 ..< side:
      let offset = 2 + 3 * (y * side + x)
      let blue = int32(input[offset])
      let green = int32(input[offset + 1])
      let red = int32(input[offset + 2])
      let gray = (114'i32 * blue + 587'i32 * green + 299'i32 * red) div 1000
      let adjusted = gray + errors[y * stride + x]
      let white = adjusted >= threshold
      let currentError = adjusted - (if white: 255'i32 else: 0'i32)
      if white: whitePixels = whitePixels or (1'u64 shl (y * side + x))
      errors[y * stride + x + 1] += truncDiv32(8'i32 * currentError)
      errors[y * stride + x + 2] += truncDiv32(4'i32 * currentError)
      errors[(y + 1) * stride + x] += truncDiv32(8'i32 * currentError)
      errors[(y + 1) * stride + x + 1] += truncDiv32(4'i32 * currentError)
      errors[(y + 1) * stride + x + 2] += truncDiv32(2'i32 * currentError)
      if x >= 1: errors[(y + 1) * stride + x - 1] += truncDiv32(4'i32 * currentError)
      if x >= 2: errors[(y + 1) * stride + x - 2] += truncDiv32(2'i32 * currentError)
  int64(whitePixels)
