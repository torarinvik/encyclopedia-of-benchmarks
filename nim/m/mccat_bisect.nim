const MaxN = 32
const MaxOutputBytes = (MaxN + 1) * 8
const Epsilon = 2.2204460492503131e-16

proc absValue(value: float64): float64 =
  if value < 0.0: -value else: value

proc sturm(diagonal, offDiagonal, beta: ptr UncheckedArray[float64],
           n: int, x: float64): int =
  var negativeCount = 0
  var q = 1.0
  for i in 0 ..< n:
    if q != 0.0: q = (diagonal[i] - x) - beta[i] / q
    else: q = (diagonal[i] - x) - absValue(offDiagonal[i]) / Epsilon
    if q < 0.0: inc negativeCount
  negativeCount

proc storeF64Le(output: ptr UncheckedArray[uint8], offset: int, value: float64) =
  let bits = cast[uint64](value)
  for i in 0 ..< 8:
    output[offset + i] = uint8((bits shr (8 * i)) and 255'u64)

proc solve(n: int, staged: ptr UncheckedArray[uint8]): int =
  var diagonal: array[MaxN, float64]
  var offDiagonal: array[MaxN, float64]
  var beta: array[MaxN, float64]
  var eigenvalues: array[MaxN + 1, float64]
  var lowerBounds: array[MaxN + 1, float64]
  for i in 0 ..< n:
    let value = float64(i + 1)
    diagonal[i] = value * value
    diagonal[i] = diagonal[i] * diagonal[i]
    offDiagonal[i] = float64(i)
    beta[i] = offDiagonal[i] * offDiagonal[i]
  beta[0] = 0.0
  offDiagonal[0] = 0.0

  const Fudge = 1.01
  var xmin = diagonal[n - 1] - Fudge * absValue(offDiagonal[n - 1])
  var xmax = diagonal[n - 1] + Fudge * absValue(offDiagonal[n - 1])
  for i in countdown(n - 2, 0):
    let h = Fudge * (absValue(offDiagonal[i]) + absValue(offDiagonal[i + 1]))
    if diagonal[i] + h > xmax: xmax = diagonal[i] + h
    if diagonal[i] - h < xmin: xmin = diagonal[i] - h
  var eps2 = Epsilon * (if xmin + xmax > 0.0: xmax else: -xmin)
  var eps1 = Epsilon
  if eps1 <= 0.0: eps1 = eps2
  eps2 = 0.5 * eps1 + 7.0 * eps2

  var x0 = xmax
  for i in countdown(n, 1):
    eigenvalues[i] = xmax
    lowerBounds[i] = xmin
  var iterations = 0
  for k in countdown(n, 1):
    var xu = xmin
    for i in countdown(k, 1):
      if xu < lowerBounds[i]:
        xu = lowerBounds[i]
        break
    if x0 > eigenvalues[k]: x0 = eigenvalues[k]
    var x1 = (xu + x0) / 2.0
    while x0 - xu > 2.0 * Epsilon * (absValue(xu) + absValue(x0)) + eps1:
      inc iterations
      let count = sturm(cast[ptr UncheckedArray[float64]](addr diagonal[0]),
                        cast[ptr UncheckedArray[float64]](addr offDiagonal[0]),
                        cast[ptr UncheckedArray[float64]](addr beta[0]), n, x1)
      if count < k:
        if count < 1:
          xu = x1
          lowerBounds[1] = x1
        else:
          xu = x1
          lowerBounds[count + 1] = x1
          if eigenvalues[count] > x1: eigenvalues[count] = x1
      else: x0 = x1
      x1 = (xu + x0) / 2.0
    eigenvalues[k] = (xu + x0) / 2.0

  var used = 0
  for i in 2 .. n:
    storeF64Le(staged, used, eigenvalues[i])
    used += 8
  storeF64Le(staged, used, eps2)
  used += 8
  storeF64Le(staged, used, float64(iterations))
  used + 8

proc mccat_bisect*(values: ptr UncheckedArray[int64], length: csize_t,
                   output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "mccat_bisect".} =
  if values == nil or length != 1: return -1
  if values[0] < 2 or values[0] > MaxN: return -1
  let n = int(values[0])
  let required = csize_t((n + 1) * 8)
  if output == nil or outputCapacity < required: return -2
  var staged: array[MaxOutputBytes, uint8]
  let used = solve(n, cast[ptr UncheckedArray[uint8]](addr staged[0]))
  for i in 0 ..< used: output[i] = staged[i]
  int64(used)
