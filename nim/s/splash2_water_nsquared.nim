const
  MaxN = 64
  MaxParseable = 260
  MaxOutputWords = 194
  Scale = 1_000_000'i64

proc truncDiv(numerator, denominator: int64): int64 =
  if numerator < 0: -((-numerator) div denominator)
  else: numerator div denominator

proc storeLe(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8((bits shr (8 * byte)) and 255'u64)

proc splash2_water_nsquared*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "splash2_water_nsquared".} =
  if input.isNil or length < 3 or length > csize_t(MaxParseable): return -1
  let nValue = input[0]
  let grid = input[1]
  let radius = input[2]
  if nValue < 0 or nValue > MaxN or grid < 1 or grid > 8 or radius < 1 or radius > 4: return -1
  let n = int(nValue)
  if length != csize_t(3 + 4 * n): return -1
  let side = grid * radius
  let radius2 = radius * radius
  var x, y, z, charge: array[MaxN, int64]
  for i in 0 ..< n:
    let at = 3 + 4 * i
    x[i] = input[at]; y[i] = input[at + 1]; z[i] = input[at + 2]; charge[i] = input[at + 3]
    if x[i] < 0 or x[i] >= side or y[i] < 0 or y[i] >= side or
       z[i] < 0 or z[i] >= side or charge[i] < -4 or charge[i] > 4: return -1
  var force: array[MaxN, array[3, int64]]
  var energy = 0'i64
  var pairs = 0'i64
  for i in 0 ..< n:
    for j in i + 1 ..< n:
      let dx = x[j] - x[i]; let dy = y[j] - y[i]; let dz = z[j] - z[i]
      let r2 = dx * dx + dy * dy + dz * dz
      if r2 >= radius2: continue
      let product = charge[i] * charge[j]
      energy += truncDiv(product * (radius2 - r2) * Scale, (1 + r2) * (1 + radius2))
      let denominator = (1 + r2) * (1 + r2)
      let fx = truncDiv(-2 * product * dx * Scale, denominator)
      let fy = truncDiv(-2 * product * dy * Scale, denominator)
      let fz = truncDiv(-2 * product * dz * Scale, denominator)
      force[i][0] += fx; force[i][1] += fy; force[i][2] += fz
      force[j][0] -= fx; force[j][1] -= fy; force[j][2] -= fz
      inc pairs
  let words = 3 * n + 2
  let outputBytes = words * 8
  if output.isNil or capacity < csize_t(outputBytes): return -2
  for i in 0 ..< n:
    for axis in 0 ..< 3: storeLe(output, 3 * i * 8 + axis * 8, force[i][axis])
  storeLe(output, 3 * n * 8, energy)
  storeLe(output, (3 * n + 1) * 8, pairs)
  int64(outputBytes)
