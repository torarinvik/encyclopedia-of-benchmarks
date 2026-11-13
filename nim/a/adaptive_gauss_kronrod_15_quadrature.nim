import std/math

const MaxInputLength = 6
const MaxIntervals = 16
const Nodes: array[7, float64] = [
  0.9914553711208126392, 0.9491079123427585245, 0.8648644233597690728,
  0.7415311855993944399, 0.5860872354676911303, 0.4058451513773971669,
  0.2077849550078984676]
const KronrodWeights: array[7, float64] = [
  0.022935322010529225, 0.06309209262997855, 0.10479001032225018,
  0.14065325971552592, 0.16900472663926790, 0.19035057806478541,
  0.20443294007529889]
const GaussWeights: array[3, float64] = [
  0.12948496616886969, 0.27970539148927667, 0.38183005050511894]

type Interval = object
  left, right, value, error: float64

proc sample(functionId: int, x: float64): float64 =
  case functionId
  of 0: exp(4.0 * x)
  of 1: sin(10.0 * x)
  of 2: 1.0 / (1.0 + 9.0 * x * x)
  else:
    let x2 = x * x
    let x4 = x2 * x2
    let x8 = x4 * x4
    x8 * x4 * x2

proc pairEstimate(functionId: int, a, b: float64): tuple[k, g: float64] =
  let center = (a + b) * 0.5
  let half = (b - a) * 0.5
  let fc = sample(functionId, center)
  var ksum = 0.2094821410847278280 * fc
  var gsum = 0.4179591836734693878 * fc
  for index in 0 ..< 7:
    let offset = half * Nodes[index]
    let pair = sample(functionId, center - offset) + sample(functionId, center + offset)
    ksum += KronrodWeights[index] * pair
    if index == 1: gsum += GaussWeights[0] * pair
    if index == 3: gsum += GaussWeights[1] * pair
    if index == 5: gsum += GaussWeights[2] * pair
  (half * ksum, half * gsum)

proc exactInteger(x: float64, low, high: int64): bool =
  if classify(x) in {fcNan, fcInf, fcNegInf} or x < float64(low) or x > float64(high):
    return false
  float64(int64(x)) == x

proc adaptiveGaussKronrod15Quadrature*(input: ptr UncheckedArray[float64], inputLength: csize_t,
    output: ptr UncheckedArray[float64], outputCapacity: csize_t): int64
    {.cdecl, exportc: "adaptive_gauss_kronrod_15_quadrature".} =
  if input == nil or inputLength != 5 or inputLength > MaxInputLength.csize_t: return -1
  if not exactInteger(input[0], 0, 3) or
      not exactInteger(input[1], -1_000_000, 1_000_000) or
      not exactInteger(input[2], -1_000_000, 1_000_000) or
      not exactInteger(input[3], 6, 8) or not exactInteger(input[4], 1, MaxIntervals): return -1
  let functionId = int(input[0])
  let aMicro = int64(input[1])
  let bMicro = int64(input[2])
  let exponent = int(input[3])
  let intervalLimit = int(input[4])
  if aMicro > bMicro: return -1
  if output == nil or outputCapacity < 1: return -2
  let a = float64(aMicro) / 1_000_000.0
  let b = float64(bMicro) / 1_000_000.0
  if a == b:
    output[0] = 0.0
    return 1
  var intervals: array[MaxIntervals, Interval]
  let initial = pairEstimate(functionId, a, b)
  intervals[0] = Interval(left: a, right: b, value: initial.k, error: abs(initial.k - initial.g))
  var count = 1
  var tolerance = 1.0
  for _ in 0 ..< exponent: tolerance *= 0.1
  while true:
    var total = 0.0
    var error = 0.0
    for index in 0 ..< count:
      total += intervals[index].value
      error += intervals[index].error
    if error <= tolerance * max(1.0, abs(total)):
      if classify(total) in {fcNan, fcInf, fcNegInf}: return -1
      output[0] = total
      return 1
    if count >= intervalLimit: return -3
    var best = 0
    for index in 1 ..< count:
      if intervals[index].error > intervals[best].error or
          (intervals[index].error == intervals[best].error and intervals[index].left < intervals[best].left):
        best = index
    let left = intervals[best].left
    let right = intervals[best].right
    let middle = (left + right) * 0.5
    let lhs = pairEstimate(functionId, left, middle)
    let rhs = pairEstimate(functionId, middle, right)
    intervals[best] = Interval(left: left, right: middle, value: lhs.k, error: abs(lhs.k - lhs.g))
    intervals[count] = Interval(left: middle, right: right, value: rhs.k, error: abs(rhs.k - rhs.g))
    inc count
