proc storeF64Le(output: ptr UncheckedArray[uint8], offset: int, value: float64) =
  var bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8(bits and 255'u64)
    bits = bits shr 8

proc ode_forward_euler*(values: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "ode_forward_euler".} =
  if values == nil or length != 4: return -1
  if values[0] < 1 or values[0] > 16 or values[1] < 1 or values[1] > 4 or
      values[2] < -10 or values[2] > 10 or values[3] < -10 or values[3] > 10: return -1
  if output == nil or outputCapacity < 16: return -2
  let dt = float64(values[1]) / 4.0
  var u = float64(values[2])
  var v = float64(values[3])
  for step in 0 ..< int(values[0]):
    let oldU = u
    let oldV = v
    u = oldU + dt * oldV
    v = oldV - dt * oldU
  storeF64Le(output, 0, u)
  storeF64Le(output, 8, v)
  16
