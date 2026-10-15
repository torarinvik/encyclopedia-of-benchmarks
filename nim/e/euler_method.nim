proc putF64Le(output: ptr UncheckedArray[uint8], offset: int, value: float64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8: output[offset + byte] = uint8((bits shr (8 * byte)) and 255)

proc euler_method*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64 {.cdecl, exportc: "euler_method".} =
  if input.isNil or length != 4: return -1
  if input[0] < -8 or input[0] > 8 or input[1] < -8 or input[1] > 8 or input[2] < 1 or input[2] > 4 or input[3] < 1 or input[3] > 16: return -1
  let steps = int(input[3]); let required = 8 * (steps + 1)
  if output.isNil or int(capacity) < required: return -2
  let h = 1.0 / float64(1 shl int(input[2]))
  var x = float64(input[0]); var y = float64(input[1])
  putF64Le(output, 0, y)
  for step in 0 ..< steps:
    y = y + h * (x + y)
    x += h
    putF64Le(output, 8 * (step + 1), y)
  int64(required)
