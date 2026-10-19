import std/math

const MaxN = 30
const MaxTsteps = 20

proc jacobi_2d*(input: ptr UncheckedArray[float64], length: csize_t,
    output: ptr UncheckedArray[float64], capacity: csize_t): int64
    {.cdecl, exportc: "jacobi_2d".} =
  if input.isNil or length != csize_t(2): return -1
  let nValue = input[0]
  let stepsValue = input[1]
  if not nValue.isFinite or not stepsValue.isFinite or
      nValue != floor(nValue) or stepsValue != floor(stepsValue) or
      nValue < 1.0 or nValue > float64(MaxN) or
      stepsValue < 0.0 or stepsValue > float64(MaxTsteps): return -1
  let n = int(nValue)
  let tsteps = int(stepsValue)
  let count = n * n
  if output.isNil or capacity < csize_t(count): return -2

  var a, b: array[MaxN, array[MaxN, float64]]
  for i in 0 ..< n:
    for j in 0 ..< n:
      a[i][j] = (float64(i) * float64(j + 2) + 2.0) / float64(n)
      b[i][j] = (float64(i) * float64(j + 3) + 3.0) / float64(n)
  for _ in 0 ..< tsteps:
    if n > 2:
      for i in 1 ..< (n - 1):
        for j in 1 ..< (n - 1):
          b[i][j] = 0.2 * (a[i][j] + a[i][j - 1] + a[i][j + 1] + a[i + 1][j] + a[i - 1][j])
      for i in 1 ..< (n - 1):
        for j in 1 ..< (n - 1):
          a[i][j] = 0.2 * (b[i][j] + b[i][j - 1] + b[i][j + 1] + b[i + 1][j] + b[i - 1][j])
  for i in 0 ..< n:
    for j in 0 ..< n: output[i * n + j] = a[i][j]
  int64(count)
