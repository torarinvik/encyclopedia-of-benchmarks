import std/math

const
  MaxDim = 4
  MaxAtoms = 4
  MaxInput = 25
  MaxGrid = 64
  InvCellLength = 0.25'f32

type Atom = object
  x, y, z, q: float32

proc decodeComponent(raw: int64): float32 = float32(raw) / 1_000_000'f32

proc quantizeQ(value: float32): int32 =
  let scaled = value * 1_000'f32
  let magnitude = abs(scaled)
  var whole = int32(magnitude)
  if magnitude - float32(whole) >= 0.5'f32: inc whole
  if scaled < 0'f32: -whole else: whole

proc writeI32Le(output: ptr UncheckedArray[uint8], offset: int, value: int32) =
  let bits = cast[uint32](value)
  output[offset] = uint8(bits and 0xff'u32)
  output[offset + 1] = uint8((bits shr 8) and 0xff'u32)
  output[offset + 2] = uint8((bits shr 16) and 0xff'u32)
  output[offset + 3] = uint8((bits shr 24) and 0xff'u32)

proc parboil_cutcp*(input: ptr UncheckedArray[int64], inputLength: csize_t,
                    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "parboil_cutcp".} =
  if input == nil or inputLength < 13 or inputLength > MaxInput: return -1
  if input[0] < 2 or input[0] > MaxDim or input[1] < 2 or input[1] > MaxDim
      or input[2] < 2 or input[2] > MaxDim or input[3] < 1 or input[3] > MaxAtoms: return -1
  let nx = int(input[0])
  let ny = int(input[1])
  let nz = int(input[2])
  let atomCount = int(input[3])
  if inputLength != csize_t(9 + 4 * atomCount): return -1
  let xloRaw = input[4]
  let yloRaw = input[5]
  let zloRaw = input[6]
  let spacingRaw = input[7]
  let cutoffRaw = input[8]
  if xloRaw < -16_000_000 or xloRaw > 16_000_000
      or yloRaw < -16_000_000 or yloRaw > 16_000_000
      or zloRaw < -16_000_000 or zloRaw > 16_000_000
      or xloRaw mod 1_000_000 != 0 or yloRaw mod 1_000_000 != 0 or zloRaw mod 1_000_000 != 0
      or spacingRaw < 1_000_000 or spacingRaw > 4_000_000 or spacingRaw mod 1_000_000 != 0
      or cutoffRaw < 250_000 or cutoffRaw > 4_000_000: return -1
  for n in 0..<atomCount:
    let offset = 9 + 4 * n
    if input[offset] < 0 or input[offset] >= nx - 1 or input[offset + 1] < 0
        or input[offset + 1] >= ny - 1 or input[offset + 2] < 0
        or input[offset + 2] >= nz - 1 or input[offset + 3] < -1_000_000
        or input[offset + 3] > 1_000_000: return -1
  let points = nx * ny * nz
  let outputBytes = 4 * points
  if output == nil or outputCapacity < csize_t(outputBytes): return -2

  let xlo = decodeComponent(xloRaw)
  let ylo = decodeComponent(yloRaw)
  let zlo = decodeComponent(zloRaw)
  let spacing = decodeComponent(spacingRaw)
  let cutoff = decodeComponent(cutoffRaw)
  let halfSpacing = spacing * 0.5'f32
  var atoms: array[MaxAtoms, Atom]
  for n in 0..<atomCount:
    let offset = 9 + 4 * n
    let ix = int(input[offset])
    let iy = int(input[offset + 1])
    let iz = int(input[offset + 2])
    atoms[n] = Atom(x: xlo + (float32(ix) * spacing + halfSpacing),
                    y: ylo + (float32(iy) * spacing + halfSpacing),
                    z: zlo + (float32(iz) * spacing + halfSpacing),
                    q: decodeComponent(input[offset + 3]))

  var minX = atoms[0].x
  var maxX = atoms[0].x
  var minY = atoms[0].y
  var maxY = atoms[0].y
  var minZ = atoms[0].z
  var maxZ = atoms[0].z
  for n in 1..<atomCount:
    minX = min(minX, atoms[n].x)
    maxX = max(maxX, atoms[n].x)
    minY = min(minY, atoms[n].y)
    maxY = max(maxY, atoms[n].y)
    minZ = min(minZ, atoms[n].z)
    maxZ = max(maxZ, atoms[n].z)
  let nxCell = int(floor(float64((maxX - minX) * InvCellLength))) + 1
  let nyCell = int(floor(float64((maxY - minY) * InvCellLength))) + 1
  let nzCell = int(floor(float64((maxZ - minZ) * InvCellLength))) + 1
  let cellCount = nxCell * nyCell * nzCell
  var first: array[MaxGrid, int]
  var next: array[MaxAtoms, int]
  for c in 0..<cellCount: first[c] = -1
  for n in 0..<atomCount: next[n] = -1
  for n in 0..<atomCount:
    if atoms[n].q == 0'f32: continue
    let i = int(floor(float64((atoms[n].x - minX) * InvCellLength)))
    let j = int(floor(float64((atoms[n].y - minY) * InvCellLength)))
    let k = int(floor(float64((atoms[n].z - minZ) * InvCellLength)))
    let cell = (k * nyCell + j) * nxCell + i
    next[n] = first[cell]
    first[cell] = n

  let cutoffSquared = cutoff * cutoff
  let invCutoffSquared = 1'f32 / cutoffSquared
  let invSpacing = 1'f32 / spacing
  let radius = int(ceil(float64(cutoff * invSpacing))) - 1
  var grid: array[MaxGrid, float32]
  for c in 0..<cellCount:
    var n = first[c]
    while n != -1:
      let x = atoms[n].x - xlo
      let y = atoms[n].y - ylo
      let z = atoms[n].z - zlo
      let q = atoms[n].q
      let ic = int(x * invSpacing)
      let jc = int(y * invSpacing)
      let kc = int(z * invSpacing)
      var ia = ic - radius
      var ib = ic + radius + 1
      var ja = jc - radius
      var jb = jc + radius + 1
      var ka = kc - radius
      var kb = kc + radius + 1
      if ia < 0: ia = 0
      if ib >= nx: ib = nx - 1
      if ja < 0: ja = 0
      if jb >= ny: jb = ny - 1
      if ka < 0: ka = 0
      if kb >= nz: kb = nz - 1
      let xstart = float32(ia) * spacing - x
      let ystart = float32(ja) * spacing - y
      var dz = float32(ka) * spacing - z
      for k in ka..kb:
        let koff = k * ny
        let dz2 = dz * dz
        var dy = ystart
        for j in ja..jb:
          let jkoff = (koff + j) * nx
          let dydz2 = dy * dy + dz2
          if dydz2 < cutoffSquared:
            var dx = xstart
            for i in ia..ib:
              let r2 = dx * dx + dydz2
              if r2 < cutoffSquared:
                let s = 1'f32 - r2 * invCutoffSquared
                let reciprocalR = float32(1.0 / sqrt(float64(r2)))
                var energy = q * reciprocalR
                energy = energy * s
                energy = energy * s
                grid[jkoff + i] = grid[jkoff + i] + energy
              dx = dx + spacing
          dy = dy + spacing
        dz = dz + spacing
      n = next[n]
  for point in 0..<points:
    writeI32Le(output, 4 * point, quantizeQ(grid[point]))
  int64(outputBytes)
