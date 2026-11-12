import std/math

const MaxN = 32
const MaxOuter = 8
const MaxSteps = 25
const MaxMicro = 1_000_000_000'i64
const Scale = 1_000_000.0

proc writeF64Le(output: ptr UncheckedArray[uint8], offset: int, value: float64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8: output[offset + byte] = uint8((bits shr (8 * byte)) and 0xFF'u64)

proc matvec(n, nnz: int, v: ptr UncheckedArray[int64], vector: var array[MaxN, float64],
            product: var array[MaxN, float64]) =
  let rowPtr = 5
  let columns = rowPtr + n + 1
  let entries = columns + nnz
  for row in 0 ..< n:
    var total = 0.0
    for edge in int(v[rowPtr + row]) ..< int(v[rowPtr + row + 1]):
      total += float64(v[entries + edge]) / Scale * vector[int(v[columns + edge])]
    product[row] = total

proc validate(v: ptr UncheckedArray[int64], length: int,
              n, outerCount, steps, nnz: var int): bool =
  if v.isNil or length < 8: return false
  if v[0] < 1 or v[0] > int64(MaxN) or v[1] < 1 or v[1] > int64(MaxOuter) or
      v[2] < 1 or v[2] > int64(MaxSteps) or v[2] > v[0] or
      v[3] < -MaxMicro or v[3] > MaxMicro or v[4] < v[0] or v[4] > 6'i64 * v[0]: return false
  n = int(v[0]); outerCount = int(v[1]); steps = int(v[2]); nnz = int(v[4])
  if length != n + 6 + 2 * nnz: return false
  let rowPtr = 5
  let columns = rowPtr + n + 1
  let entries = columns + nnz
  if v[rowPtr] != 0 or v[rowPtr + n] != int64(nnz): return false
  for row in 0 ..< n:
    let begin = int(v[rowPtr + row])
    let end = int(v[rowPtr + row + 1])
    if begin < 0 or begin >= end or end > nnz: return false
    var diagonal = 0'i64
    var offSum = 0'i64
    var previous = -1'i64
    for edge in begin ..< end:
      let column = v[columns + edge]
      let entry = v[entries + edge]
      if column < 0 or column >= int64(n) or column <= previous or entry == 0 or
          entry < -MaxMicro or entry > MaxMicro: return false
      previous = column
      if column == int64(row): diagonal = entry
      else: offSum += abs(entry)
    if diagonal <= 0 or diagonal <= offSum: return false
  for row in 0 ..< n:
    for edge in int(v[rowPtr + row]) ..< int(v[rowPtr + row + 1]):
      let column = int(v[columns + edge])
      var found = false
      for reverse in int(v[rowPtr + column]) ..< int(v[rowPtr + column + 1]):
        if v[columns + reverse] == int64(row) and v[entries + reverse] == v[entries + edge]:
          found = true
          break
      if not found: return false
  true

proc npb_cg_sparse_inverse_power*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "npb_cg_sparse_inverse_power".} =
  var n, outerCount, steps, nnz: int
  if not validate(input, int(length), n, outerCount, steps, nnz): return -1
  let outputBytes = outerCount * 16
  if output.isNil or int(capacity) < outputBytes: return -2
  var x, z, residual, direction, product, az: array[MaxN, float64]
  for i in 0 ..< n: x[i] = 1.0
  for outer in 0 ..< outerCount:
    var rhsSquared = 0.0
    for i in 0 ..< n:
      z[i] = 0.0; residual[i] = x[i]; direction[i] = x[i]
      rhsSquared += residual[i] * residual[i]
    var residualSquared = rhsSquared
    for _ in 0 ..< steps:
      if residualSquared <= 0.0: break
      matvec(n, nnz, input, direction, product)
      var denominator = 0.0
      for i in 0 ..< n: denominator += direction[i] * product[i]
      if denominator <= 0.0 or denominator.classify in {fcNan, fcInf, fcNegInf}: return -1
      let alpha = residualSquared / denominator
      for i in 0 ..< n:
        z[i] += alpha * direction[i]
        residual[i] -= alpha * product[i]
      var nextSquared = 0.0
      for i in 0 ..< n: nextSquared += residual[i] * residual[i]
      if nextSquared <= rhsSquared * 1.0e-28:
        residualSquared = nextSquared
        break
      let beta = nextSquared / residualSquared
      for i in 0 ..< n: direction[i] = residual[i] + beta * direction[i]
      residualSquared = nextSquared
    matvec(n, nnz, input, z, az)
    var explicitSquared = 0.0
    var xDotZ = 0.0
    var zSquared = 0.0
    for i in 0 ..< n:
      let difference = x[i] - az[i]
      explicitSquared += difference * difference
      xDotZ += x[i] * z[i]
      zSquared += z[i] * z[i]
    if xDotZ <= 0.0 or zSquared <= 0.0 or xDotZ.classify in {fcNan, fcInf, fcNegInf} or
        zSquared.classify in {fcNan, fcInf, fcNegInf}: return -1
    let estimate = float64(input[3]) / Scale + 1.0 / xDotZ
    let residualNorm = sqrt(explicitSquared)
    if estimate.classify in {fcNan, fcInf, fcNegInf} or residualNorm.classify in {fcNan, fcInf, fcNegInf}: return -1
    writeF64Le(output, outer * 16, estimate)
    writeF64Le(output, outer * 16 + 8, residualNorm)
    let zNorm = sqrt(zSquared)
    for i in 0 ..< n: x[i] = z[i] / zNorm
  int64(outputBytes)
