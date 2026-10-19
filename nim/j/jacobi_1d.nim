import std/math

const MaxN = 30
const MaxTsteps = 20

proc jacobi_1d*(input: ptr UncheckedArray[float64], length: csize_t,
    output: ptr UncheckedArray[float64], capacity: csize_t): int64
    {.cdecl, exportc: "jacobi_1d".} =
  if input.isNil or length != csize_t(2): return -1
  let nValue = input[0]
  let stepsValue = input[1]
  if not nValue.isFinite or not stepsValue.isFinite or
      nValue != floor(nValue) or stepsValue != floor(stepsValue) or
      nValue < 1.0 or nValue > float64(MaxN) or
      stepsValue < 0.0 or stepsValue > float64(MaxTsteps): return -1
  let n = int(nValue)
  let tsteps = int(stepsValue)
  if output.isNil or capacity < csize_t(n): return -2

  var a, b: array[MaxN, float64]
  for i in 0 ..< n:
    a[i] = (float64(i) + 2.0) / float64(n)
    b[i] = (float64(i) + 3.0) / float64(n)
  for _ in 0 ..< tsteps:
    if n > 2:
      for i in 1 ..< n - 1: b[i] = 0.33333 * (a[i - 1] + a[i] + a[i + 1])
      for i in 1 ..< n - 1: a[i] = 0.33333 * (b[i - 1] + b[i] + b[i + 1])
  for i in 0 ..< n: output[i] = a[i]
  int64(n)
