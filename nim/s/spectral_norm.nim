import math

const maxDimension = 64
const invalidResult = -1e300
type Vector = array[maxDimension, float64]

proc matrixEntry(i, j: int): float64 =
  let triangular = (i + j) * (i + j + 1) div 2
  1.0 / float64(triangular + i + 1)

proc multiplyA(n: int, input: Vector, output: var Vector) =
  for i in 0 ..< n:
    var total = 0.0
    for j in 0 ..< n: total += matrixEntry(i, j) * input[j]
    output[i] = total

proc multiplyAt(n: int, input: Vector, output: var Vector) =
  for i in 0 ..< n:
    var total = 0.0
    for j in 0 ..< n: total += matrixEntry(j, i) * input[j]
    output[i] = total

proc multiplyAta(n: int, input: Vector, output: var Vector, temporary: var Vector) =
  multiplyA(n, input, temporary)
  multiplyAt(n, temporary, output)

proc spectral_norm*(values: ptr int64, length: uint64): float64 {.cdecl, exportc: "spectral_norm".} =
  if values == nil or length != 1 or values[0] < 1 or values[0] > maxDimension: return invalidResult
  let n = int(values[0])
  var u: Vector
  var v: Vector
  var temporary: Vector
  for i in 0 ..< n: u[i] = 1.0
  for _ in 0 ..< 10:
    multiplyAta(n, u, v, temporary)
    multiplyAta(n, v, u, temporary)
  var vBv = 0.0
  var vv = 0.0
  for i in 0 ..< n:
    vBv += u[i] * v[i]
    vv += v[i] * v[i]
  sqrt(vBv / vv)
