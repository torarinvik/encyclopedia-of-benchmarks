import math

const MaxSamples = 8
const MaxOutput = 12

proc pca*(input: ptr UncheckedArray[float64], inputLength: csize_t,
    output: ptr UncheckedArray[float64], capacity: csize_t): int64 {.cdecl, exportc: "pca".} =
  if input == nil or inputLength < 9 or inputLength > 19: return -1
  if input[1] != 2.0 or input[2] != 1.0: return -1
  if input[0] < 3.0 or input[0] > 8.0 or input[0] != floor(input[0]): return -1
  let n = int(input[0])
  if inputLength != csize_t(3 + 2 * n): return -1
  var x, y, z0, z1: array[MaxSamples, float64]
  var mean0 = 0.0
  var mean1 = 0.0
  for i in 0 ..< n:
    x[i] = input[3 + 2 * i]
    y[i] = input[4 + 2 * i]
    if x[i] != x[i] or y[i] != y[i] or abs(x[i]) > 1000.0 or abs(y[i]) > 1000.0: return -1
    mean0 += x[i]
    mean1 += y[i]
  mean0 /= float64(n)
  mean1 /= float64(n)
  var sum0 = 0.0
  var sum1 = 0.0
  for i in 0 ..< n:
    let dx = x[i] - mean0
    let dy = y[i] - mean1
    sum0 += dx * dx
    sum1 += dy * dy
  let denom = float64(n - 1)
  if sum0 <= 0.0 or sum1 <= 0.0: return -1
  let scale0 = sqrt(sum0 / denom)
  let scale1 = sqrt(sum1 / denom)
  var a = 0.0
  var b = 0.0
  var d = 0.0
  for i in 0 ..< n:
    z0[i] = (x[i] - mean0) / scale0
    z1[i] = (y[i] - mean1) / scale1
    a += z0[i] * z0[i]
    b += z0[i] * z1[i]
    d += z1[i] * z1[i]
  a /= denom
  b /= denom
  d /= denom
  let root = sqrt((a - d) * (a - d) + 4.0 * b * b)
  let lambda0 = 0.5 * (a + d + root)
  let lambda1 = 0.5 * (a + d - root)
  if lambda0 - lambda1 <= 1e-8: return -1
  var vx, vy: float64
  if b == 0.0:
    if a >= d: vx = 1.0 else: vy = 1.0
  else:
    vx = b
    vy = lambda0 - a
    let norm = sqrt(vx * vx + vy * vy)
    if norm == 0.0: return -1
    vx /= norm
    vy /= norm
  if (abs(vx) >= abs(vy) and vx < 0.0) or (abs(vy) > abs(vx) and vy < 0.0):
    vx = -vx
    vy = -vy
  var staged: array[MaxOutput, float64]
  for i in 0 ..< n: staged[i] = z0[i] * vx + z1[i] * vy
  staged[n] = vx
  staged[n + 1] = vy
  staged[n + 2] = lambda0
  staged[n + 3] = lambda1
  let outputSize = n + 4
  if output == nil or capacity < csize_t(outputSize): return -2
  for i in 0 ..< outputSize: output[i] = staged[i]
  int64(outputSize)
