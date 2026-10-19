const maxDimension = 64
const maxCells = maxDimension * maxDimension
const invalidResult = -1e300

type Matrix = array[maxCells, float64]
type Vector = array[maxDimension, float64]

proc polybench_ludcmp*(values: ptr UncheckedArray[int64], length: csize_t): float64
    {.cdecl, exportc: "polybench_ludcmp".} =
  if values == nil or length != 1: return invalidResult
  if values[0] < 1 or values[0] > maxDimension: return invalidResult
  let n = int(values[0])
  var a, product: Matrix
  var b, x, y: Vector
  for i in 0 ..< n:
    x[i] = 0.0
    y[i] = 0.0
    b[i] = (float64(i + 1) / float64(n)) / 2.0 + 4.0
  for i in 0 ..< n:
    for j in 0 .. i: a[i * n + j] = float64(-(j mod n)) / float64(n) + 1.0
    for j in i + 1 ..< n: a[i * n + j] = 0.0
    a[i * n + i] = 1.0
  for r in 0 ..< n:
    for s in 0 ..< n: product[r * n + s] = 0.0
  for t in 0 ..< n:
    for r in 0 ..< n:
      for s in 0 ..< n:
        product[r * n + s] = product[r * n + s] + a[r * n + t] * a[s * n + t]
  for r in 0 ..< n:
    for s in 0 ..< n: a[r * n + s] = product[r * n + s]
  for i in 0 ..< n:
    for j in 0 ..< i:
      var w = a[i * n + j]
      for k in 0 ..< j: w = w - a[i * n + k] * a[k * n + j]
      a[i * n + j] = w / a[j * n + j]
    for j in i ..< n:
      var w = a[i * n + j]
      for k in 0 ..< i: w = w - a[i * n + k] * a[k * n + j]
      a[i * n + j] = w
  for i in 0 ..< n:
    var w = b[i]
    for j in 0 ..< i: w = w - a[i * n + j] * y[j]
    y[i] = w
  for rev in 1 .. n:
    let i = n - rev
    var w = y[i]
    for j in i + 1 ..< n: w = w - a[i * n + j] * x[j]
    x[i] = w / a[i * n + i]
  var result = 0.0
  for i in 0 ..< n: result += x[i]
  result
