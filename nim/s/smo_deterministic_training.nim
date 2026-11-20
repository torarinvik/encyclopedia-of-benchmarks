import std/math

const MaxN = 8
const MaxD = 3
const MaxInput = 37
const Tolerance = 0.001
const Epsilon = 0.001

proc field(x: float64, low, high: int64): bool =
  classify(x) notin {fcNan, fcInf, fcNegInf} and x >= float64(low) and
    x <= float64(high) and float64(int64(x)) == x

proc kernel(points: array[MaxN * MaxD, float64], i, j, d: int): float64 =
  for k in 0 ..< d:
    result += points[i * MaxD + k] * points[j * MaxD + k]

proc decision(index: int, alpha: array[MaxN, float64], bias: float64,
              labels: array[MaxN, int64], points: array[MaxN * MaxD, float64],
              n, d: int): float64 =
  result = bias
  for k in 0 ..< n:
    result += alpha[k] * float64(labels[k]) * kernel(points, k, index, d)

proc dual(alpha: array[MaxN, float64], labels: array[MaxN, int64],
          points: array[MaxN * MaxD, float64], n, d: int): float64 =
  for i in 0 ..< n: result += alpha[i]
  for i in 0 ..< n:
    for j in 0 ..< n:
      result -= 0.5 * alpha[i] * alpha[j] * float64(labels[i] * labels[j]) * kernel(points, i, j, d)

proc takeStep(i, j: int, alpha: var array[MaxN, float64], bias: var float64,
              c: float64, labels: array[MaxN, int64],
              points: array[MaxN * MaxD, float64], n, d: int): bool =
  if i == j: return false
  let yi = labels[i]
  let yj = labels[j]
  let sign = yi * yj
  let oldI = alpha[i]
  let oldJ = alpha[j]
  let errorI = decision(i, alpha, bias, labels, points, n, d) - float64(yi)
  let errorJ = decision(j, alpha, bias, labels, points, n, d) - float64(yj)
  var low, high: float64
  if yi != yj:
    low = max(0.0, oldJ - oldI)
    high = min(c, c + oldJ - oldI)
  else:
    low = max(0.0, oldI + oldJ - c)
    high = min(c, oldI + oldJ)
  if low == high: return false
  let kii = kernel(points, i, i, d)
  let kjj = kernel(points, j, j, d)
  let kij = kernel(points, i, j, d)
  let curvature = kii + kjj - 2.0 * kij
  var nextJ: float64
  if curvature > 0.0:
    nextJ = min(high, max(low, oldJ + float64(yj) * (errorI - errorJ) / curvature))
  else:
    var trial = alpha
    trial[i] = oldI + float64(sign) * (oldJ - low)
    trial[j] = low
    let lowScore = dual(trial, labels, points, n, d)
    trial[i] = oldI + float64(sign) * (oldJ - high)
    trial[j] = high
    let highScore = dual(trial, labels, points, n, d)
    if lowScore > highScore + Epsilon: nextJ = low
    elif highScore > lowScore + Epsilon: nextJ = high
    else: nextJ = oldJ
  if abs(nextJ - oldJ) < Epsilon * (nextJ + oldJ + Epsilon): return false
  let nextI = oldI + float64(sign) * (oldJ - nextJ)
  let deltaI = nextI - oldI
  let deltaJ = nextJ - oldJ
  let biasI = bias - errorI - float64(yi) * deltaI * kii - float64(yj) * deltaJ * kij
  let biasJ = bias - errorJ - float64(yi) * deltaI * kij - float64(yj) * deltaJ * kjj
  if nextI > 0.0 and nextI < c: bias = biasI
  elif nextJ > 0.0 and nextJ < c: bias = biasJ
  else: bias = 0.5 * (biasI + biasJ)
  alpha[i] = nextI
  alpha[j] = nextJ
  true

proc examine(j: int, alpha: var array[MaxN, float64], bias: var float64,
             c: float64, labels: array[MaxN, int64],
             points: array[MaxN * MaxD, float64], n, d: int): bool =
  let errorJ = decision(j, alpha, bias, labels, points, n, d) - float64(labels[j])
  let residual = errorJ * float64(labels[j])
  if not ((residual < -Tolerance and alpha[j] < c) or
          (residual > Tolerance and alpha[j] > 0.0)): return false
  var freeCount = 0
  var preferred = -1
  var greatestGap = -1.0
  for i in 0 ..< n:
    if alpha[i] > 0.0 and alpha[i] < c:
      inc freeCount
      let errorI = decision(i, alpha, bias, labels, points, n, d) - float64(labels[i])
      let gap = abs(errorI - errorJ)
      if gap > greatestGap:
        greatestGap = gap
        preferred = i
  if freeCount > 1 and takeStep(preferred, j, alpha, bias, c, labels, points, n, d): return true
  for i in 0 ..< n:
    if alpha[i] > 0.0 and alpha[i] < c and takeStep(i, j, alpha, bias, c, labels, points, n, d):
      return true
  for i in 0 ..< n:
    if takeStep(i, j, alpha, bias, c, labels, points, n, d): return true
  false

proc smo_deterministic_training*(input: ptr UncheckedArray[float64], inputLength: csize_t,
    output: ptr UncheckedArray[float64], outputCapacity: csize_t): int64
    {.cdecl, exportc: "smo_deterministic_training".} =
  if input == nil or inputLength < 4 or inputLength > MaxInput.csize_t: return -1
  if not field(input[0], 2, MaxN) or not field(input[1], 1, MaxD) or
      not field(input[2], 1, 5000) or not field(input[3], 1, 16): return -1
  let n = int(input[0])
  let d = int(input[1])
  let cMilli = int64(input[2])
  let passCap = int(input[3])
  if inputLength != csize_t(4 + n + n * d): return -1
  var labels: array[MaxN, int64]
  var alpha: array[MaxN, float64]
  var points: array[MaxN * MaxD, float64]
  var positive = false
  var negative = false
  var at = 4
  for i in 0 ..< n:
    if not field(input[at], -1, 1) or input[at] == 0.0: return -1
    labels[i] = int64(input[at])
    positive = positive or labels[i] > 0
    negative = negative or labels[i] < 0
    inc at
  if not positive or not negative: return -1
  for i in 0 ..< n:
    for k in 0 ..< d:
      if not field(input[at], -32, 32): return -1
      points[i * MaxD + k] = input[at]
      inc at
  if output == nil or outputCapacity < csize_t(n + 4): return -2

  let c = float64(cMilli) / 1000.0
  var bias = 0.0
  var changed = 0
  var examineAll = true
  var passes = 0
  while passes < passCap and (changed > 0 or examineAll):
    changed = 0
    for j in 0 ..< n:
      if (examineAll or (alpha[j] > 0.0 and alpha[j] < c)) and
          examine(j, alpha, bias, c, labels, points, n, d): inc changed
    inc passes
    if examineAll: examineAll = false
    elif changed == 0: examineAll = true
  var staged: array[MaxN + 4, float64]
  staged[0] = float64(passes)
  staged[1] = float64(changed)
  staged[2] = if passes < passCap and changed == 0 and not examineAll: 1.0 else: 0.0
  for i in 0 ..< n: staged[3 + i] = alpha[i]
  staged[3 + n] = bias
  for i in 0 ..< n + 4: output[i] = staged[i]
  int64(n + 4)
