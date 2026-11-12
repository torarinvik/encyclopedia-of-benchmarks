const MaxPoints = 32
const MaxAxis = 4
const MaxSweeps = 8
const MaxMicro = 1_000_000_000'i64
const Scale = 1_000_000.0

proc absMicro(value: int64): int64 =
  if value < 0: -value else: value

proc solveBlock(d: array[25, float64], rhs: array[5, float64],
                result: var array[5, float64]): bool =
  var a = d
  var b = rhs
  for pivot in 0 ..< 5:
    let diagonal = a[pivot * 5 + pivot]
    if diagonal <= 0.0: return false
    for row in pivot + 1 ..< 5:
      let factor = a[row * 5 + pivot] / diagonal
      for column in pivot + 1 ..< 5:
        a[row * 5 + column] -= factor * a[pivot * 5 + column]
      b[row] -= factor * b[pivot]
  for back in 0 ..< 5:
    let row = 4 - back
    var tail = 0.0
    for column in row + 1 ..< 5:
      tail += a[row * 5 + column] * result[column]
    result[row] = (b[row] - tail) / a[row * 5 + row]
  true

proc applyOperator(nx, ny, nz: int, d: array[25, float64], c: array[3, float64],
                   x: array[MaxPoints * 5, float64],
                   out: var array[MaxPoints * 5, float64]) =
  let points = nx * ny * nz
  let nxy = nx * ny
  for point in 0 ..< points:
    let ix = point mod nx
    let iy = (point div nx) mod ny
    let iz = point div nxy
    for row in 0 ..< 5:
      var total = 0.0
      for column in 0 ..< 5:
        total += d[row * 5 + column] * x[point * 5 + column]
      if ix > 0: total += c[0] * x[(point - 1) * 5 + row]
      if ix + 1 < nx: total += c[0] * x[(point + 1) * 5 + row]
      if iy > 0: total += c[1] * x[(point - nx) * 5 + row]
      if iy + 1 < ny: total += c[1] * x[(point + nx) * 5 + row]
      if iz > 0: total += c[2] * x[(point - nxy) * 5 + row]
      if iz + 1 < nz: total += c[2] * x[(point + nxy) * 5 + row]
      out[point * 5 + row] = total

proc writeFloat64(output: ptr UncheckedArray[uint8], offset: int, value: float64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8((bits shr (8 * byte)) and 255'u64)

proc npb_lu_block_ssor*(input: ptr UncheckedArray[int64], length: csize_t,
                        output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "npb_lu_block_ssor".} =
  if input.isNil or length < 42 or length > 352: return -1
  if input[0] < 1 or input[0] > int64(MaxAxis) or input[1] < 1 or input[1] > int64(MaxAxis) or
      input[2] < 1 or input[2] > int64(MaxAxis) or input[3] < 1 or input[3] > int64(MaxSweeps): return -1
  let nx = int(input[0]); let ny = int(input[1]); let nz = int(input[2])
  let sweeps = int(input[3]); let points = nx * ny * nz; let count = points * 5
  if points > MaxPoints or int(length) != 32 + 10 * points: return -1
  for index in 4 ..< int(length):
    if input[index] < -MaxMicro or input[index] > MaxMicro: return -1
  for row in 0 ..< 5:
    let diagonal = input[4 + row * 5 + row]
    var offSum = 0'i64
    for column in 0 ..< 5:
      let entry = input[4 + row * 5 + column]
      if entry != input[4 + column * 5 + row]: return -1
      if column != row: offSum += absMicro(entry)
    if nx > 1: offSum += 2 * absMicro(input[29])
    if ny > 1: offSum += 2 * absMicro(input[30])
    if nz > 1: offSum += 2 * absMicro(input[31])
    if diagonal <= 0 or diagonal <= offSum: return -1

  let outputBytes = 8 * (sweeps + count)
  if output.isNil or int(outputCapacity) < outputBytes: return -2
  var d: array[25, float64]
  var c: array[3, float64]
  var x, rhs, applied, residual, forward, correction: array[MaxPoints * 5, float64]
  for index in 0 ..< 25: d[index] = float64(input[4 + index]) / Scale
  for axis in 0 ..< 3: c[axis] = float64(input[29 + axis]) / Scale
  for index in 0 ..< count:
    rhs[index] = float64(input[32 + index]) / Scale
    x[index] = float64(input[32 + count + index]) / Scale
  let nxy = nx * ny
  for sweep in 0 ..< sweeps:
    applyOperator(nx, ny, nz, d, c, x, applied)
    for index in 0 ..< count: residual[index] = rhs[index] - applied[index]
    for point in 0 ..< points:
      let ix = point mod nx; let iy = (point div nx) mod ny; let iz = point div nxy
      var local: array[5, float64]
      var solved: array[5, float64]
      for row in 0 ..< 5: local[row] = residual[point * 5 + row]
      if ix > 0:
        for row in 0 ..< 5: local[row] -= c[0] * forward[(point - 1) * 5 + row]
      if iy > 0:
        for row in 0 ..< 5: local[row] -= c[1] * forward[(point - nx) * 5 + row]
      if iz > 0:
        for row in 0 ..< 5: local[row] -= c[2] * forward[(point - nxy) * 5 + row]
      if not solveBlock(d, local, solved): return -1
      for row in 0 ..< 5: forward[point * 5 + row] = solved[row]
    for back in 0 ..< points:
      let point = points - 1 - back
      let ix = point mod nx; let iy = (point div nx) mod ny; let iz = point div nxy
      var local: array[5, float64]
      var solved: array[5, float64]
      for row in 0 ..< 5:
        for column in 0 ..< 5: local[row] += d[row * 5 + column] * forward[point * 5 + column]
      if ix + 1 < nx:
        for row in 0 ..< 5: local[row] -= c[0] * correction[(point + 1) * 5 + row]
      if iy + 1 < ny:
        for row in 0 ..< 5: local[row] -= c[1] * correction[(point + nx) * 5 + row]
      if iz + 1 < nz:
        for row in 0 ..< 5: local[row] -= c[2] * correction[(point + nxy) * 5 + row]
      if not solveBlock(d, local, solved): return -1
      for row in 0 ..< 5: correction[point * 5 + row] = solved[row]
    for index in 0 ..< count: x[index] += correction[index]
    applyOperator(nx, ny, nz, d, c, x, applied)
    var norm2 = 0.0
    for index in 0 ..< count:
      let difference = rhs[index] - applied[index]
      norm2 += difference * difference
    writeFloat64(output, sweep * 8, sqrt(norm2))
  for index in 0 ..< count: writeFloat64(output, (sweeps + index) * 8, x[index])
  int64(outputBytes)
