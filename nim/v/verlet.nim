import std/math

proc verlet*(values: ptr UncheckedArray[float64], length: csize_t,
    output: ptr UncheckedArray[float64], capacity: csize_t): int64 {.cdecl, exportc: "verlet".} =
  if values == nil or length != 4: return -1
  for i in 0 ..< 4:
    if classify(values[i]) == fcNan: return -1
  if values[0] < 2.0 or values[0] > 32.0 or values[0] != floor(values[0]) or
      values[1] < -1.0 or values[1] > 1.0 or
      values[2] < -1.0 or values[2] > 1.0 or
      values[3] < 0.0 or values[3] > 4.0 or values[3] != floor(values[3]): return -1

  let n = int(values[0])
  let code = int(values[3])
  var dt = 0.00390625
  case code
  of 1: dt = 0.0078125
  of 2: dt = 0.015625
  of 3: dt = 0.03125
  of 4: dt = 0.0625
  else: discard
  let dtSquared = dt * dt
  if output == nil or capacity < csize_t(2 * n): return -2

  output[0] = values[1]
  output[1] = values[1] + values[2] * dt + 0.5 * (-values[1]) * dtSquared
  for i in 1 ..< n - 1:
    output[i + 1] = 2.0 * output[i] - output[i - 1] + (-output[i]) * dtSquared
  for i in 0 ..< n:
    output[n + i] = float64(i) * dt
  int64(2 * n)
