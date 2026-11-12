const MaxMolecules = 64
const MaxGridSide = 8
const MaxCells = 512
const MaxInputLength = 4 + 4 * MaxMolecules
const Scale = 1_000_000'i64

proc truncDiv(numerator, denominator: int64): int64 =
  if numerator < 0: -((-numerator) div denominator)
  else: numerator div denominator

proc storeI64Le(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8((bits shr (8 * byte)) and 255)

proc water_spatial*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "water_spatial".} =
  if input.isNil or length < 3 or length > csize_t(MaxInputLength): return -1
  let countValue = input[0]
  let gridValue = input[1]
  let cutoff = input[2]
  if countValue < 0 or countValue > MaxMolecules or gridValue < 1 or gridValue > MaxGridSide
      or cutoff < 1 or cutoff > 4: return -1
  let count = int(countValue)
  let grid = int(gridValue)
  if length != csize_t(3 + 4 * count): return -1
  let extent = int64(grid) * cutoff
  for index in 0 ..< count:
    let base = 3 + 4 * index
    if input[base] < 0 or input[base] >= extent or input[base + 1] < 0
        or input[base + 1] >= extent or input[base + 2] < 0
        or input[base + 2] >= extent or input[base + 3] < -4
        or input[base + 3] > 4: return -1
  let outputBytes = 8 * (3 * count + 2)
  if output.isNil or capacity < csize_t(outputBytes): return -2

  var head: array[MaxCells, int64]
  var next: array[MaxMolecules, int64]
  var forceX, forceY, forceZ: array[MaxMolecules, int64]
  for cell in 0 ..< MaxCells: head[cell] = -1
  for index in 0 ..< count:
    let base = 3 + 4 * index
    let cx = int(input[base] div cutoff)
    let cy = int(input[base + 1] div cutoff)
    let cz = int(input[base + 2] div cutoff)
    let cell = cx + grid * (cy + grid * cz)
    next[index] = head[cell]
    head[cell] = int64(index)

  var energy = 0'i64
  var pairs = 0'i64
  let cutoffSquared = cutoff * cutoff
  for index in 0 ..< count:
    let baseI = 3 + 4 * index
    let cx = int(input[baseI] div cutoff)
    let cy = int(input[baseI + 1] div cutoff)
    let cz = int(input[baseI + 2] div cutoff)
    for oz in -1 .. 1:
      let nz = cz + oz
      if nz < 0 or nz >= grid: continue
      for oy in -1 .. 1:
        let ny = cy + oy
        if ny < 0 or ny >= grid: continue
        for ox in -1 .. 1:
          let nx = cx + ox
          if nx < 0 or nx >= grid: continue
          let cell = nx + grid * (ny + grid * nz)
          var candidate = head[cell]
          while candidate >= 0:
            let other = int(candidate)
            if other > index:
              let baseJ = 3 + 4 * other
              let dx = input[baseJ] - input[baseI]
              let dy = input[baseJ + 1] - input[baseI + 1]
              let dz = input[baseJ + 2] - input[baseI + 2]
              let r2 = dx * dx + dy * dy + dz * dz
              if r2 < cutoffSquared:
                let product = input[baseI + 3] * input[baseJ + 3]
                energy += truncDiv(product * (cutoffSquared - r2) * Scale,
                                   (1 + r2) * (1 + cutoffSquared))
                let denominator = (1 + r2) * (1 + r2)
                let px = truncDiv(-2 * product * dx * Scale, denominator)
                let py = truncDiv(-2 * product * dy * Scale, denominator)
                let pz = truncDiv(-2 * product * dz * Scale, denominator)
                forceX[index] += px; forceX[other] -= px
                forceY[index] += py; forceY[other] -= py
                forceZ[index] += pz; forceZ[other] -= pz
                inc pairs
            candidate = next[other]
  for index in 0 ..< count:
    storeI64Le(output, 8 * (3 * index), forceX[index])
    storeI64Le(output, 8 * (3 * index + 1), forceY[index])
    storeI64Le(output, 8 * (3 * index + 2), forceZ[index])
  storeI64Le(output, 8 * (3 * count), energy)
  storeI64Le(output, 8 * (3 * count + 1), pairs)
  int64(outputBytes)
