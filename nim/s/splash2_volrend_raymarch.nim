const
  MaxSide = 8
  MaxRays = 16
  MaxSamples = 32
  MaxVoxels = MaxSide * MaxSide * MaxSide
  MaxParseable = 3 + 2 * MaxVoxels + 6 * MaxRays + 1
  MaxMaskCells = 4 * MaxVoxels
  Q8 = 256'i64
  Q16 = 65_536'i64
  WeightDen = 16_777_216'i64
  AlphaDen = 255'i64 * WeightDen
  ColorDen = 255'i64 * 255'i64 * WeightDen

proc voxelIndex(side, x, y, z: int): int = (z * side + y) * side + x
proc maskIndex(level, x, y, z: int): int = ((level * 8 + z) * 8 + y) * 8 + x

proc roundHalfUp(numerator, denominator: int64): int64 =
  (numerator + denominator div 2) div denominator

proc toByte(q16: int64): uint8 = uint8((q16 * 255 + Q16 div 2) div Q16)

proc interpolate(side: int, alpha, gray: openArray[uint8], xq, yq, zq: int64): tuple[opacity, gray: int64] =
  let low = [int(xq div Q8), int(yq div Q8), int(zq div Q8)]
  let frac = [int(xq mod Q8), int(yq mod Q8), int(zq mod Q8)]
  let high = [min(low[0] + 1, side - 1), min(low[1] + 1, side - 1), min(low[2] + 1, side - 1)]
  var opacitySum = 0'i64
  var premulSum = 0'i64
  for dz in 0 .. 1:
    let z = if dz == 0: low[2] else: high[2]
    let wz = if dz == 0: int(Q8) - frac[2] else: frac[2]
    for dy in 0 .. 1:
      let y = if dy == 0: low[1] else: high[1]
      let wy = if dy == 0: int(Q8) - frac[1] else: frac[1]
      for dx in 0 .. 1:
        let x = if dx == 0: low[0] else: high[0]
        let wx = if dx == 0: int(Q8) - frac[0] else: frac[0]
        let at = voxelIndex(side, x, y, z)
        let weight = int64(wx * wy * wz)
        opacitySum += int64(alpha[at]) * weight
        premulSum += int64(alpha[at]) * int64(gray[at]) * weight
  result.opacity = roundHalfUp(opacitySum * Q16, AlphaDen)
  result.gray = roundHalfUp(premulSum * Q16, ColorDen)

proc splash2_volrend_raymarch*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "splash2_volrend_raymarch".} =
  if input.isNil or length < 3 or length > csize_t(MaxParseable): return -1
  let sideRaw = input[0]
  let rayRaw = input[1]
  let sampleRaw = input[2]
  if (sideRaw != 2 and sideRaw != 4 and sideRaw != 8) or rayRaw < 1 or rayRaw > MaxRays or sampleRaw < 1 or sampleRaw > MaxSamples: return -1
  let side = int(sideRaw)
  let rayCount = int(rayRaw)
  let samples = int(sampleRaw)
  let voxelCount = side * side * side
  let rayStart = 3 + 2 * voxelCount
  if length != csize_t(rayStart + 6 * rayCount): return -1

  var alpha: array[MaxVoxels, uint8]
  var gray: array[MaxVoxels, uint8]
  var rays: array[MaxRays * 6, int32]
  for voxel in 0 ..< voxelCount:
    let a = input[3 + 2 * voxel]
    let g = input[4 + 2 * voxel]
    if a < 0 or a > 255 or g < 0 or g > 255: return -1
    alpha[voxel] = uint8(a)
    gray[voxel] = uint8(g)

  let coordMax = int64(side - 1) * Q8
  for ray in 0 ..< rayCount:
    let at = rayStart + 6 * ray
    for axis in 0 .. 2:
      let origin = input[at + axis]
      let delta = input[at + axis + 3]
      if origin < 0 or origin > coordMax or delta < -coordMax or delta > coordMax: return -1
      rays[6 * ray + axis] = int32(origin)
      rays[6 * ray + axis + 3] = int32(delta)
    if samples > 1 and rays[6 * ray + 3] == 0 and rays[6 * ray + 4] == 0 and rays[6 * ray + 5] == 0: return -1
    for sample in 0 ..< samples:
      for axis in 0 .. 2:
        let q = int64(rays[6 * ray + axis]) + int64(sample) * int64(rays[6 * ray + axis + 3])
        if q < 0 or q > coordMax: return -1

  let outputBytes = 5 * rayCount
  if output.isNil: return -2
  if capacity < csize_t(outputBytes): return -3

  var support: array[MaxMaskCells, uint8]
  for z in 0 ..< side:
    for y in 0 ..< side:
      for x in 0 ..< side:
        var occupied = false
        for dz in 0 .. 1:
          for dy in 0 .. 1:
            for dx in 0 .. 1:
              let nx = min(x + dx, side - 1)
              let ny = min(y + dy, side - 1)
              let nz = min(z + dz, side - 1)
              if alpha[voxelIndex(side, nx, ny, nz)] != 0: occupied = true
        support[maskIndex(0, x, y, z)] = uint8(ord(occupied))
  var levels = 0
  var dimension = side
  while dimension > 1:
    inc levels
    dimension = dimension div 2
  for level in 1 .. levels:
    let dim = side shr level
    for z in 0 ..< dim:
      for y in 0 ..< dim:
        for x in 0 ..< dim:
          var occupied = false
          for dz in 0 .. 1:
            for dy in 0 .. 1:
              for dx in 0 .. 1:
                if support[maskIndex(level - 1, 2 * x + dx, 2 * y + dy, 2 * z + dz)] != 0: occupied = true
          support[maskIndex(level, x, y, z)] = uint8(ord(occupied))

  for ray in 0 ..< rayCount:
    var accumulatedAlpha = 0'i64
    var accumulatedGray = 0'i64
    var used = 0
    for sample in 0 ..< samples:
      used = sample + 1
      let xq = int64(rays[6 * ray]) + int64(sample) * int64(rays[6 * ray + 3])
      let yq = int64(rays[6 * ray + 1]) + int64(sample) * int64(rays[6 * ray + 4])
      let zq = int64(rays[6 * ray + 2]) + int64(sample) * int64(rays[6 * ray + 5])
      let cx = int(xq div Q8)
      let cy = int(yq div Q8)
      let cz = int(zq div Q8)
      var supported = true
      for level in countdown(levels, 0):
        if support[maskIndex(level, cx shr level, cy shr level, cz shr level)] == 0:
          supported = false
          break
      if supported:
        let values = interpolate(side, alpha, gray, xq, yq, zq)
        let remaining = Q16 - accumulatedAlpha
        accumulatedAlpha = min(Q16, accumulatedAlpha + roundHalfUp(remaining * values.opacity, Q16))
        accumulatedGray = min(Q16, accumulatedGray + roundHalfUp(remaining * values.gray, Q16))
        if accumulatedAlpha == Q16: break
    let at = 5 * ray
    let value = toByte(accumulatedGray)
    output[at] = value
    output[at + 1] = value
    output[at + 2] = value
    output[at + 3] = toByte(accumulatedAlpha)
    output[at + 4] = uint8(used)
  int64(outputBytes)
