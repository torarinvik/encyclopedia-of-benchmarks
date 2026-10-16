proc putF64Le(output: ptr UncheckedArray[uint8], offset: int, value: float64) =
  let bits = cast[uint64](value)
  for byte in 0..<8: output[offset + byte] = uint8((bits shr (8 * byte)) and 0xFF'u64)

proc damped_oscillator*(input: ptr UncheckedArray[int64], length: csize_t, output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "damped_oscillator".} =
  if input == nil or length != 5: return -1
  if input[0] < 1 or input[0] > 1024 or input[1] < 0 or input[1] > 1024 or
      input[2] < -1024 or input[2] > 1024 or input[3] < -1024 or input[3] > 1024 or
      input[4] < 1 or input[4] > 1024: return -1
  if output == nil or capacity < 16: return -2
  let omega0 = float64(input[0]) / 1024.0
  let gamma = float64(input[1]) / 1024.0
  let x = float64(input[2]) / 1024.0
  let v = float64(input[3]) / 1024.0
  let dt = float64(input[4]) / 1024.0
  let acceleration = -2.0 * gamma * v - omega0 * omega0 * x
  let xNext = x + dt * v
  let vNext = v + dt * acceleration
  putF64Le(output, 0, xNext)
  putF64Le(output, 8, vNext)
  16
