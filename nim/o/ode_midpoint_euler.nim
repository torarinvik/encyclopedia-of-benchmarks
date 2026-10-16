const MaxSteps = 8
const OutputBytes = 16

proc putF64Le(output: ptr UncheckedArray[uint8], offset: int, value: float64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8((bits shr (8 * byte)) and 0xFF'u64)

proc ode_midpoint_euler*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "ode_midpoint_euler".} =
  if input.isNil or length != 4: return -1
  let steps = input[0]
  let dtQuarters = input[1]
  let u0 = input[2]
  let v0 = input[3]
  if steps < 1 or steps > MaxSteps or dtQuarters < 1 or dtQuarters > 4 or
      u0 < -10 or u0 > 10 or v0 < -10 or v0 > 10: return -1
  if output.isNil or capacity < OutputBytes: return -2

  let dt = float64(dtQuarters) / 4.0
  let halfDt = 0.5 * dt
  var u = float64(u0)
  var v = float64(v0)
  var step = 0'i64
  while step < steps:
    let midpointU = u + halfDt * v
    let midpointV = v - halfDt * u
    let nextU = u + dt * midpointV
    let nextV = v - dt * midpointU
    u = nextU
    v = nextV
    inc step
  putF64Le(output, 0, u)
  putF64Le(output, 8, v)
  OutputBytes.int64
