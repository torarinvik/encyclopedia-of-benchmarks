import std/math

const MaxN = 40

proc durbin*(input: ptr UncheckedArray[float64], length: csize_t,
    output: ptr UncheckedArray[float64], capacity: csize_t): int64
    {.cdecl, exportc: "durbin".} =
  if input.isNil or length != csize_t(1): return -1
  let nValue = input[0]
  if not nValue.isFinite or nValue != floor(nValue) or nValue < 1.0 or nValue > float64(MaxN): return -1
  let n = int(nValue)
  if output.isNil or capacity < csize_t(n): return -2

  var r, y, z: array[MaxN, float64]
  for i in 0 ..< n: r[i] = float64(n + 1 - i)
  y[0] = -r[0]
  var beta = 1.0
  var alpha = -r[0]
  for k in 1 ..< n:
    beta = (1.0 - alpha * alpha) * beta
    var total = 0.0
    for i in 0 ..< k: total += r[k - i - 1] * y[i]
    alpha = -(r[k] + total) / beta
    for i in 0 ..< k: z[i] = y[i] + alpha * y[k - i - 1]
    for i in 0 ..< k: y[i] = z[i]
    y[k] = alpha
  for i in 0 ..< n: output[i] = y[i]
  int64(n)
