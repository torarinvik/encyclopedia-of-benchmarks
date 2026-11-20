import std/math

const ComponentLimit = 1_000_000.0
const AngleLimit = 6.283185307179586
const OutputLimit = 2_000_000.0

proc rodrigues_arbitrary_axis_rotation*(input: ptr UncheckedArray[float64], inputLen: csize_t,
                                        output: ptr UncheckedArray[float64], outputCapacity: csize_t): int64
    {.cdecl, exportc: "rodrigues_arbitrary_axis_rotation".} =
  if input.isNil or inputLen != 7: return -1
  for i in 0..<6:
    if input[i] != input[i] or input[i] < -ComponentLimit or input[i] > ComponentLimit: return -1
  let theta = input[6]
  if theta != theta or theta < -AngleLimit or theta > AngleLimit: return -1
  var scale = abs(input[0])
  if abs(input[1]) > scale: scale = abs(input[1])
  if abs(input[2]) > scale: scale = abs(input[2])
  if scale == 0.0: return -1
  let qx = input[0] / scale
  let qy = input[1] / scale
  let qz = input[2] / scale
  let norm = sqrt((qx * qx + qy * qy) + qz * qz)
  if norm != norm or norm == 0.0: return -1
  let nx = qx / norm
  let ny = qy / norm
  let nz = qz / norm
  let vx = input[3]
  let vy = input[4]
  let vz = input[5]
  let cosine = cos(theta)
  let sine = sin(theta)
  let oneMinusCosine = 1.0 - cosine
  let cx = ny * vz - nz * vy
  let cy = nz * vx - nx * vz
  let cz = nx * vy - ny * vx
  let dot = (nx * vx + ny * vy) + nz * vz
  let result = [
    (vx * cosine + cx * sine) + (nx * dot) * oneMinusCosine,
    (vy * cosine + cy * sine) + (ny * dot) * oneMinusCosine,
    (vz * cosine + cz * sine) + (nz * dot) * oneMinusCosine,
  ]
  for value in result:
    if value != value or value < -OutputLimit or value > OutputLimit: return -1
  if output.isNil or outputCapacity < 3: return -2
  for i in 0..<3: output[i] = result[i]
  3
