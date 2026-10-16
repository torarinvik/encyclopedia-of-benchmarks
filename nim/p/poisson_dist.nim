## Bounded Poisson rate, expectation, point probability, and range probability.
import std/math

const MaxMilliValue = 100_000'i64
const MaxSuccessCount = 20'i64
const InvalidResult = -1.0e300

proc poissonFactorial(x: float64): float64 =
  var factorial = x
  var index = int64(x) - 1
  while index > 0:
    factorial *= float64(index)
    dec index
  if factorial <= 0.0: factorial = 1.0
  factorial

proc poissonPoint(mean: float64, successes: int64): float64 =
  (pow(mean, float64(successes)) * exp(-mean)) / poissonFactorial(float64(successes))

proc poisson_dist*(input: ptr UncheckedArray[int64], length: csize_t): float64
    {.cdecl, exportc: "poisson_dist".} =
  if input.isNil or length != 4: return InvalidResult
  let operation = input[0]
  let first = input[1]
  let second = input[2]
  let third = input[3]

  if operation == 0:
    if first < 0 or first > MaxMilliValue or second < 1 or second > MaxMilliValue or third != 0:
      return InvalidResult
    return (float64(first) / 1000.0) / (float64(second) / 1000.0)
  if operation == 1:
    if first < 0 or first > MaxMilliValue or second < 0 or second > MaxMilliValue or third != 0:
      return InvalidResult
    return (float64(first) / 1000.0) * (float64(second) / 1000.0)
  if operation == 2:
    if first < 0 or first > MaxMilliValue or second < 0 or second > MaxSuccessCount or third != 0:
      return InvalidResult
    return poissonPoint(float64(first) / 1000.0, second)
  if operation == 3:
    if first < 0 or first > MaxMilliValue or second < 0 or second > third or third > MaxSuccessCount:
      return InvalidResult
    let mean = float64(first) / 1000.0
    var probability = 0.0
    var successes = second
    while successes <= third:
      probability += poissonPoint(mean, successes)
      inc successes
    return probability
  InvalidResult
