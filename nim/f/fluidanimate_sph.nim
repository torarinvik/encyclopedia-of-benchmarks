import std/math

const MaxParticles = 32
const MaxInputLength = 2 + 6 * MaxParticles
const Pi = 3.14159265358979323846264338327950288

proc storeF64Le(output: ptr UncheckedArray[uint8], offset: int, value: float64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8((bits shr (8 * byte)) and 255)

proc fluidanimate_sph*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "fluidanimate_sph".} =
  if input.isNil or length < 2 or length > csize_t(MaxInputLength): return -1
  let countValue = input[0]
  let rpmMilli = input[1]
  if countValue < 1 or countValue > MaxParticles or rpmMilli < 500 or rpmMilli > 5000: return -1
  let count = int(countValue)
  if length != csize_t(2 + 6 * count): return -1
  for i in 0 ..< count:
    let base = 2 + 6 * i
    for axis in 0 ..< 3:
      if input[base + axis] < -10000 or input[base + axis] > 10000: return -1
      if input[base + 3 + axis] < -5000 or input[base + 3 + axis] > 5000: return -1
  let outputBytes = 40 * count
  if output.isNil or capacity < csize_t(outputBytes): return -2

  var position: array[MaxParticles, array[3, float64]]
  var velocity: array[MaxParticles, array[3, float64]]
  var acceleration: array[MaxParticles, array[3, float64]]
  var density: array[MaxParticles, float64]
  let rpm = float64(rpmMilli) / 1000.0
  let h = 1.695 / rpm
  let h2 = h * h
  let mass = 1000.0 / (rpm * rpm * rpm)
  let densityCoeff = mass * (315.0 / (64.0 * Pi * pow(h, 9.0)))
  let pressureCoeff = 3.0 * (15.0 / (Pi * pow(h, 6.0))) * 1.5 * mass
  let viscosityCoeff = 0.4 * (45.0 / (Pi * pow(h, 6.0))) * mass
  for i in 0 ..< count:
    let base = 2 + 6 * i
    for axis in 0 ..< 3:
      position[i][axis] = float64(input[base + axis]) / 1000.0
      velocity[i][axis] = float64(input[base + 3 + axis]) / 1000.0
      acceleration[i][axis] = if axis == 1: -9.8 else: 0.0
    density[i] = densityCoeff * h2 * h2 * h2
  for i in 0 ..< count:
    for j in i + 1 ..< count:
      let dx = position[i][0] - position[j][0]
      let dy = position[i][1] - position[j][1]
      let dz = position[i][2] - position[j][2]
      let r2 = dx * dx + dy * dy + dz * dz
      if r2 < h2:
        let term = densityCoeff * pow(h2 - r2, 3.0)
        density[i] += term
        density[j] += term
  for i in 0 ..< count:
    for j in i + 1 ..< count:
      let dx = position[i][0] - position[j][0]
      let dy = position[i][1] - position[j][1]
      let dz = position[i][2] - position[j][2]
      let r2 = dx * dx + dy * dy + dz * dz
      if r2 >= h2: continue
      let distance = sqrt(max(r2, 1e-12))
      let hmr = h - distance
      let rhoProduct = density[i] * density[j]
      let pressureScale = pressureCoeff * (hmr * hmr / distance) *
        (density[i] + density[j] - 2000.0) / rhoProduct
      let viscosityScale = viscosityCoeff * hmr / rhoProduct
      let displacement = [dx, dy, dz]
      for axis in 0 ..< 3:
        let force = displacement[axis] * pressureScale +
          (velocity[j][axis] - velocity[i][axis]) * viscosityScale
        acceleration[i][axis] += force
        acceleration[j][axis] -= force
  for i in 0 ..< count:
    let fields = [density[i], 3.0 * (density[i] - 1000.0),
      acceleration[i][0], acceleration[i][1], acceleration[i][2]]
    for field in 0 ..< 5:
      storeF64Le(output, 8 * (5 * i + field), fields[field])
  int64(outputBytes)
