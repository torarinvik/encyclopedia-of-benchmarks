import std/math

const MaxN = 8
const MaxD = 3
const MaxInput = 47

proc field(x: float64, low, high: int64): bool =
  classify(x) notin {fcNan, fcInf, fcNegInf} and
    x >= float64(low) and x <= float64(high) and float64(int64(x)) == x

proc dot(x: array[MaxN * MaxD, float64], a, b, d: int): float64 =
  for r in 0 ..< d:
    result += x[a * MaxD + r] * x[b * MaxD + r]

proc objective(alpha: array[MaxN, float64], labels: array[MaxN, int64],
               x: array[MaxN * MaxD, float64], n, d: int): float64 =
  for p in 0 ..< n: result += alpha[p]
  for p in 0 ..< n:
    for q in 0 ..< n:
      result -= 0.5 * alpha[p] * alpha[q] * float64(labels[p] * labels[q]) * dot(x, p, q, d)

proc smo_dual_pair_update*(input: ptr UncheckedArray[float64], inputLength: csize_t,
    output: ptr UncheckedArray[float64], outputCapacity: csize_t): int64
    {.cdecl, exportc: "smo_dual_pair_update".} =
  if input == nil or inputLength < 6 or inputLength > MaxInput.csize_t: return -1
  if not field(input[0], 2, MaxN) or not field(input[1], 1, MaxD) or
      not field(input[2], 1, 5000) or not field(input[3], -1_000_000, 1_000_000): return -1
  let n = int(input[0])
  let d = int(input[1])
  let cMilli = int64(input[2])
  let bMilli = int64(input[3])
  if inputLength != csize_t(6 + 2 * n + n * d): return -1

  var labels: array[MaxN, int64]
  var alpha: array[MaxN, float64]
  var x: array[MaxN * MaxD, float64]
  var negative = false
  var positive = false
  var equality = 0'i64
  var at = 4
  for k in 0 ..< n:
    if not field(input[at], -1, 1) or input[at] == 0.0: return -1
    labels[k] = int64(input[at])
    negative = negative or labels[k] < 0
    positive = positive or labels[k] > 0
    inc at
  for k in 0 ..< n:
    if not field(input[at], 0, cMilli): return -1
    let value = int64(input[at])
    alpha[k] = float64(value) / 1000.0
    equality += labels[k] * value
    inc at
  if not negative or not positive or equality != 0: return -1
  for row in 0 ..< n:
    for col in 0 ..< d:
      if not field(input[at], -32, 32): return -1
      x[row * MaxD + col] = input[at]
      inc at
  if not field(input[at], 0, int64(n - 1)) or not field(input[at + 1], 0, int64(n - 1)): return -1
  let i = int(input[at])
  let j = int(input[at + 1])
  if i == j: return -1
  if output == nil or outputCapacity < csize_t(n + 1): return -2

  let cValue = float64(cMilli) / 1000.0
  let bias = float64(bMilli) / 1000.0
  let yi = labels[i]
  let yj = labels[j]
  let sign = yi * yj
  let oldI = alpha[i]
  let oldJ = alpha[j]
  let kii = dot(x, i, i, d)
  let kjj = dot(x, j, j, d)
  let kij = dot(x, i, j, d)
  var errorI = bias - float64(yi)
  var errorJ = bias - float64(yj)
  for k in 0 ..< n:
    errorI += alpha[k] * float64(labels[k]) * dot(x, k, i, d)
    errorJ += alpha[k] * float64(labels[k]) * dot(x, k, j, d)
  var low, high: float64
  if yi != yj:
    low = max(0.0, oldJ - oldI)
    high = min(cValue, cValue + oldJ - oldI)
  else:
    low = max(0.0, oldI + oldJ - cValue)
    high = min(cValue, oldI + oldJ)
  let eta = 2.0 * kij - kii - kjj
  var newJ: float64
  if eta < 0.0:
    newJ = min(high, max(low, oldJ - float64(yj) * (errorI - errorJ) / eta))
  else:
    var candidate = alpha
    candidate[i] = oldI + float64(sign) * (oldJ - low)
    candidate[j] = low
    let lowScore = objective(candidate, labels, x, n, d)
    candidate[i] = oldI + float64(sign) * (oldJ - high)
    candidate[j] = high
    let highScore = objective(candidate, labels, x, n, d)
    newJ = if highScore > lowScore: high else: low
  let newI = oldI + float64(sign) * (oldJ - newJ)
  let deltaI = newI - oldI
  let deltaJ = newJ - oldJ
  let biasI = bias - errorI - float64(yi) * deltaI * kii - float64(yj) * deltaJ * kij
  let biasJ = bias - errorJ - float64(yi) * deltaI * kij - float64(yj) * deltaJ * kjj
  let newBias = if 0.0 < newI and newI < cValue: biasI
    elif 0.0 < newJ and newJ < cValue: biasJ
    else: 0.5 * (biasI + biasJ)
  alpha[i] = newI
  alpha[j] = newJ
  for k in 0 ..< n: output[k] = alpha[k]
  output[n] = newBias
  int64(n + 1)
