import std/math

const CoordinateLimit = 1_000_000.0
const AngleLimit = 1_000_000.0
const OutputLimit = 2_000_000.0
const Pi = 3.14159265358979323846

proc vector3_axis_rotation*(input: ptr UncheckedArray[float64], inputLen: csize_t,
                            output: ptr UncheckedArray[float64], outputCapacity: csize_t): int64
    {.cdecl, exportc: "vector3_axis_rotation".} =
  if input.isNil or inputLen != 5: return -1
  for i in 0..<3:
    if input[i] != input[i] or input[i] < -CoordinateLimit or input[i] > CoordinateLimit: return -1
  let axis = input[3]
  var angle = input[4]
  if (axis != 0.0 and axis != 1.0 and axis != 2.0) or angle != angle or
      angle < -AngleLimit or angle > AngleLimit: return -1
  angle = angle - floor(angle / 360.0) * 360.0
  if angle == 0.0: angle = 0.0
  angle = angle / 450.0 * 180.0 / Pi
  let x = input[0]
  let y = input[1]
  let z = input[2]
  let cosine = cos(angle)
  let sine = sin(angle)
  var result: array[3, float64]
  if axis == 0.0:
    result = [x, y * cosine - z * sine, z * cosine + y * sine]
  elif axis == 1.0:
    result = [x * cosine - z * sine, y, z * cosine + x * sine]
  else:
    result = [x * cosine - y * sine, y * cosine + x * sine, z]
  for value in result:
    if value != value or value < -OutputLimit or value > OutputLimit: return -1
  if output.isNil or outputCapacity < 3: return -2
  for i in 0..<3: output[i] = result[i]
  3
