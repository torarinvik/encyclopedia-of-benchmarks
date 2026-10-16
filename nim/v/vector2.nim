import std/math

proc vector2*(values: ptr UncheckedArray[float64], length: csize_t,
    output: ptr UncheckedArray[float64], capacity: csize_t): int64 {.cdecl, exportc: "vector2".} =
  if values == nil or length != 6: return -1
  for i in 0 ..< 6:
    if values[i] != values[i] or values[i] > 1e100 or values[i] < -1e100: return -1
  if values[0] < 0.0 or values[0] > 10.0 or values[0] != floor(values[0]): return -1
  for i in 1 .. 4:
    if values[i] < -1000.0 or values[i] > 1000.0: return -1

  let op = int(values[0])
  let ax = values[1]
  let ay = values[2]
  let bx = values[3]
  let by = values[4]
  let scalar = values[5]
  if op == 1:
    if scalar < 0.0 or scalar > 2000.0: return -1
  elif op == 6:
    if bx != 0.0 or by != 0.0 or scalar < -1000.0 or scalar > 1000.0: return -1
  elif op == 9:
    if bx != 0.0 or by != 0.0 or scalar < -6.283185307179586 or scalar > 6.283185307179586: return -1
  elif scalar != 0.0: return -1
  if op in [2, 3] and (bx != 0.0 or by != 0.0): return -1

  var result: array[2, float64] = [0.0, 0.0]
  var resultLength = 1
  case op
  of 0:
    if ax == bx and ay == by: result[0] = 1.0
  of 1:
    if abs(ax - bx) < scalar and abs(ay - by) < scalar: result[0] = 1.0
  of 2:
    result[0] = sqrt(ax * ax + ay * ay)
  of 3:
    let magnitude = sqrt(ax * ax + ay * ay)
    if magnitude == 0.0: return -1
    resultLength = 2
    result[0] = ax / magnitude
    result[1] = ay / magnitude
  of 4:
    resultLength = 2
    result[0] = ax + bx
    result[1] = ay + by
  of 5:
    resultLength = 2
    result[0] = ax - bx
    result[1] = ay - by
  of 6:
    resultLength = 2
    result[0] = ax * scalar
    result[1] = ay * scalar
  of 7:
    let dx = bx - ax
    let dy = by - ay
    result[0] = sqrt(dx * dx + dy * dy)
  of 8:
    result[0] = ax * bx + ay * by
  of 9:
    let cosine = cos(scalar)
    let sine = sin(scalar)
    resultLength = 2
    result[0] = cosine * ax - sine * ay
    result[1] = sine * ax + cosine * ay
  else:
    result[0] = arctan2(by, bx) - arctan2(ay, ax)

  if output == nil or capacity < csize_t(resultLength): return -2
  for i in 0 ..< resultLength: output[i] = result[i]
  int64(resultLength)
