const maxDimension = 64
const maxCells = maxDimension * maxDimension
const invalidResult = -1e300

type Matrix = array[maxCells, float64]

proc polybench_symm*(values: ptr UncheckedArray[int64], length: csize_t): float64
    {.cdecl, exportc: "polybench_symm".} =
  if values == nil or length != 2: return invalidResult
  if values[0] < 1 or values[0] > maxDimension or values[1] < 1 or values[1] > maxDimension:
    return invalidResult
  let m = int(values[0])
  let n = int(values[1])
  var a, b, c: Matrix
  let alpha = 1.5
  let beta = 1.2
  for i in 0 ..< m:
    for j in 0 ..< n:
      c[i * n + j] = float64((i + j) mod 100) / float64(m)
      b[i * n + j] = float64((n + i - j) mod 100) / float64(m)
  for i in 0 ..< m:
    for j in 0 ..< m:
      if j <= i: a[i * m + j] = float64((i + j) mod 100) / float64(m)
      else: a[i * m + j] = -999.0
  for i in 0 ..< m:
    for j in 0 ..< n:
      var temp2 = 0.0
      for k in 0 ..< i:
        c[k * n + j] = c[k * n + j] + alpha * b[i * n + j] * a[i * m + k]
        temp2 = temp2 + b[k * n + j] * a[i * m + k]
      c[i * n + j] = beta * c[i * n + j] + alpha * b[i * n + j] * a[i * m + i] + alpha * temp2
  var result = 0.0
  for i in 0 ..< m:
    for j in 0 ..< n: result += c[i * n + j]
  result
