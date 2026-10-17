import std/math

proc quaternions*(input: ptr UncheckedArray[float64], length: csize_t,
    output: ptr UncheckedArray[float64], capacity: csize_t): int64
    {.cdecl, exportc: "quaternions".} =
  if input.isNil or length < 1 or length > 10: return -1
  for i in 0 ..< int(length):
    if input[i] != input[i]: return -1
  let op = input[0]
  if op != 0.0 and op != 1.0 and op != 2.0: return -1
  let mode = int(op)
  let expected = if mode == 0: 4 elif mode == 1: 5 else: 9
  let count = if mode == 1: 3 else: 4
  if int(length) != expected: return -1

  var values: array[8, float32]
  if mode == 0:
    for i in 1 ..< 4:
      if input[i] < -3.0 or input[i] > 3.0: return -1
      values[i - 1] = float32(input[i])
  elif mode == 1:
    for i in 1 ..< 5:
      values[i - 1] = float32(input[i])
      if values[i - 1] < -1.0 or values[i - 1] > 1.0: return -1
    let (w, a, b, c) = (values[0], values[1], values[2], values[3])
    var norm = w * w
    norm = norm + a * a
    norm = norm + b * b
    norm = norm + c * c
    if abs(norm - 1.0'f32) > 1e-6'f32: return -1
    var pitchArgument = w * b + a * c
    pitchArgument = 2.0'f32 * pitchArgument
    if pitchArgument < -1.0 or pitchArgument > 1.0: return -1
  else:
    for i in 1 ..< 9:
      if input[i] < -1.0 or input[i] > 1.0: return -1
      values[i - 1] = float32(input[i])

  if output.isNil or capacity < csize_t(count): return -2
  var result: array[4, float32]
  if mode == 0:
    let (yaw, pitch, roll) = (values[0], values[1], values[2])
    let cy = cos(yaw * 0.5'f32)
    let sy = sin(yaw * 0.5'f32)
    let cp = cos(pitch * 0.5'f32)
    let sp = sin(pitch * 0.5'f32)
    let cr = cos(roll * 0.5'f32)
    let sr = sin(roll * 0.5'f32)
    result[0] = (cr * cp) * cy + (sr * sp) * sy
    result[1] = (sr * cp) * cy - (cr * sp) * sy
    result[2] = (cr * sp) * cy + (sr * cp) * sy
    result[3] = (cr * cp) * sy - (sr * sp) * cy
  elif mode == 1:
    let (w, a, b, c) = (values[0], values[1], values[2], values[3])
    let rollY = 2.0'f32 * (w * a + b * c)
    let rollX = 1.0'f32 - 2.0'f32 * (a * a + b * b)
    let pitch = arcsin(2.0'f32 * (w * b + a * c))
    let yawY = 2.0'f32 * (w * c + a * b)
    let yawX = 1.0'f32 - 2.0'f32 * (b * b + c * c)
    result[0] = arctan2(rollY, rollX)
    result[1] = pitch
    result[2] = arctan2(yawY, yawX)
  else:
    let (aw, a1, a2, a3, bw, b1, b2, b3) =
      (values[0], values[1], values[2], values[3], values[4], values[5], values[6], values[7])
    result[0] = ((aw * bw - a1 * b1) - a2 * b2) - a3 * b3
    result[1] = ((aw * b1 + a1 * bw) + a2 * b3) - a3 * b2
    result[2] = ((aw * b2 - a1 * b3) + a2 * bw) + a3 * b1
    result[3] = ((aw * b3 + a1 * b2) - a2 * b1) + a3 * bw

  for i in 0 ..< count: output[i] = float64(result[i])
  int64(count)
