import std/math

const Side = 4
const Cells = 64
const MaxSources = 8

proc wrapIndex(value, side: int): int =
  if value < 0: value + side
  elif value >= side: value - side
  else: value

proc gridIndex(x, y, z, side: int): int = x + side * (y + side * z)

proc stencil(src: array[64, float64], dst: var array[64, float64], side: int,
             center, face, edge, corner: float64) =
  for z in 0 ..< side:
    for y in 0 ..< side:
      for x in 0 ..< side:
        let q = gridIndex(x, y, z, side)
        var total = center * src[q]
        for dz in -1 .. 1:
          for dy in -1 .. 1:
            for dx in -1 .. 1:
              let distance = abs(dx) + abs(dy) + abs(dz)
              if distance == 0: continue
              let weight = if distance == 1: face elif distance == 2: edge else: corner
              let neighbor = gridIndex(wrapIndex(x+dx, side), wrapIndex(y+dy, side), wrapIndex(z+dz, side), side)
              total += weight * src[neighbor]
        dst[q] = total

proc restrictGrid(fine: array[64, float64], side: int, coarse: var array[64, float64]) =
  let half = side div 2
  for z in 0 ..< half:
    for y in 0 ..< half:
      for x in 0 ..< half:
        var total = 0.0
        for dz in -1 .. 1:
          for dy in -1 .. 1:
            for dx in -1 .. 1:
              let wx = if dx == 0: 1.0 else: 0.5
              let wy = if dy == 0: 1.0 else: 0.5
              let wz = if dz == 0: 1.0 else: 0.5
              let q = gridIndex(wrapIndex(2*x+dx, side), wrapIndex(2*y+dy, side), wrapIndex(2*z+dz, side), side)
              total += wx * wy * wz * fine[q]
        coarse[gridIndex(x, y, z, half)] = 0.5 * total

proc interpolateGrid(coarse: array[64, float64], half: int, fine: var array[64, float64]) =
  let side = 2 * half
  for z in 0 ..< side:
    for y in 0 ..< side:
      for x in 0 ..< side:
        let bx = x div 2
        let by = y div 2
        let bz = z div 2
        let nx = if (x and 1) == 1: 2 else: 1
        let ny = if (y and 1) == 1: 2 else: 1
        let nz = if (z and 1) == 1: 2 else: 1
        let wx = if (x and 1) == 1: 0.5 else: 1.0
        let wy = if (y and 1) == 1: 0.5 else: 1.0
        let wz = if (z and 1) == 1: 0.5 else: 1.0
        var total = 0.0
        for iz in 0 ..< nz:
          for iy in 0 ..< ny:
            for ix in 0 ..< nx:
              total += wx * wy * wz * coarse[gridIndex((bx+ix) mod half, (by+iy) mod half, (bz+iz) mod half, half)]
        fine[gridIndex(x, y, z, side)] = total

proc vcycle(rhs: array[64, float64], side: int): array[64, float64] =
  if side == 2:
    stencil(rhs, result, side, -3.0/8.0, 1.0/32.0, -1.0/64.0, 0.0)
    return
  let half = side div 2
  var coarseRhs, coarseSolution, prolonged, applied, remaining, post: array[64, float64]
  restrictGrid(rhs, side, coarseRhs)
  coarseSolution = vcycle(coarseRhs, half)
  interpolateGrid(coarseSolution, half, prolonged)
  stencil(prolonged, applied, side, -8.0/3.0, 0.0, 1.0/6.0, 1.0/12.0)
  for q in 0 ..< side*side*side: remaining[q] = rhs[q] - applied[q]
  stencil(remaining, post, side, -3.0/8.0, 1.0/32.0, -1.0/64.0, 0.0)
  for q in 0 ..< side*side*side: result[q] = prolonged[q] + post[q]

proc npb_mg_vcycle*(input: ptr UncheckedArray[float64], length: csize_t,
    output: ptr UncheckedArray[float64], capacity: csize_t): int64
    {.cdecl, exportc: "npb_mg_vcycle".} =
  if input.isNil or length < csize_t(2) or length > csize_t(34): return -1
  let iterationValue = input[0]
  let countValue = input[1]
  if not iterationValue.isFinite or not countValue.isFinite or
      iterationValue != floor(iterationValue) or countValue != floor(countValue) or
      iterationValue < 1.0 or iterationValue > 4.0 or countValue < 0.0 or countValue > float64(MaxSources): return -1
  let iterations = int(iterationValue)
  let count = int(countValue)
  if int(length) != 2 + 4 * count: return -1
  var rhs, solution, applied, residual, correction: array[Cells, float64]
  var seen: array[Cells, bool]
  for source in 0 ..< count:
    let base = 2 + 4 * source
    let xv, yv, zv, value = input[base], input[base+1], input[base+2], input[base+3]
    for coordinate in [xv, yv, zv]:
      if not coordinate.isFinite or coordinate != floor(coordinate) or coordinate < 0.0 or coordinate >= float64(Side): return -1
    if not value.isFinite or value < -4.0 or value > 4.0: return -1
    let q = gridIndex(int(xv), int(yv), int(zv), Side)
    if seen[q]: return -1
    seen[q] = true
    rhs[q] = value
  if output.isNil or capacity < csize_t(1): return -2
  for _ in 0 ..< iterations:
    stencil(solution, applied, Side, -8.0/3.0, 0.0, 1.0/6.0, 1.0/12.0)
    for q in 0 ..< Cells: residual[q] = rhs[q] - applied[q]
    correction = vcycle(residual, Side)
    for q in 0 ..< Cells: solution[q] += correction[q]
  var checksum = 0.0
  for q in 0 ..< Cells: checksum += solution[q]
  output[0] = checksum
  1
