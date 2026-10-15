proc putF64Le(output: ptr UncheckedArray[uint8], offset: int, value: float64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8: output[offset + byte] = uint8((bits shr (8 * byte)) and 255)

proc euler_method_julia*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64 {.cdecl, exportc: "euler_method_julia".} =
  if input.isNil or length != 3: return -1
  if input[0] < -8 or input[0] > 8 or input[1] < 1 or input[1] > 16 or input[2] < 1 or input[2] > 4: return -1
  let steps = int(input[1]); let required = 16 * steps
  if output.isNil or int(capacity) < required: return -2
  let h = 1.0 / float64(1 shl int(input[2]))
  var states: array[16, float64]; var times: array[16, float64]
  states[0] = float64(input[0])
  for i in 0 ..< steps - 1:
    states[i+1] = states[i] + h * (states[i] + times[i])
    times[i+1] = times[i] + h
  for i in 0 ..< steps:
    putF64Le(output, 8*i, states[i]); putF64Le(output, 8*(steps+i), times[i])
  int64(required)
