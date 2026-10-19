import std/math

const MaxN = 40

proc trisolv*(input: ptr UncheckedArray[float64], length: csize_t,
    output: ptr UncheckedArray[float64], capacity: csize_t): int64
    {.cdecl, exportc: "trisolv".} =
  if input.isNil or length != csize_t(1): return -1
  let nValue = input[0]
  if not nValue.isFinite or nValue != floor(nValue) or nValue < 1.0 or nValue > float64(MaxN): return -1
  let n = int(nValue)
  if output.isNil or capacity < csize_t(n): return -2

  var lower: array[MaxN, array[MaxN, float64]]
  var b, x: array[MaxN, float64]
  for i in 0 ..< n:
    b[i] = float64(i)
    for j in 0 .. i:
      lower[i][j] = float64(i + n - j + 1) * 2.0 / float64(n)
  for i in 0 ..< n:
    x[i] = b[i]
    for j in 0 ..< i: x[i] -= lower[i][j] * x[j]
    x[i] /= lower[i][i]
  for i in 0 ..< n: output[i] = x[i]
  int64(n)
