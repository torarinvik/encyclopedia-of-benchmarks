import math

const MaxInputLength = 6
const InvalidResult = -1.0e300

proc objective(operation: int64, x: float64): float64 =
  let delta = if operation == 0: x - 1.0 else: x + 1.0
  let square = delta * delta
  if operation == 0: -square else: square

proc ternarySearch(operation: int64, a: float64, b: float64, epsilon: float64,
                   frame: int64, maxCalls: int64): float64 =
  if abs(a - b) <= epsilon: return objective(operation, (a + b) / 2.0)

  let left = (2.0 * a + b) / 3.0
  let right = (a + 2.0 * b) / 3.0
  let leftValue = objective(operation, left)
  let rightValue = objective(operation, right)
  let takeLeft = if operation == 0: leftValue < rightValue else: leftValue > rightValue
  if frame >= maxCalls: return InvalidResult
  if takeLeft: return ternarySearch(operation, left, b, epsilon, frame + 1, maxCalls)
  ternarySearch(operation, a, right, epsilon, frame + 1, maxCalls)

proc ternary*(input: ptr UncheckedArray[int64], length: csize_t): float64
    {.cdecl, exportc: "ternary".} =
  if input.isNil or length < 5 or length > csize_t(MaxInputLength): return InvalidResult
  let operation = input[0]
  let aMilli = input[1]
  let bMilli = input[2]
  let epsilonMicro = input[3]
  let maxCalls = input[4]
  if length != 5 or (operation != 0 and operation != 1) or
      aMilli < -1_000_000 or aMilli > bMilli or bMilli > 1_000_000 or
      epsilonMicro < 1 or epsilonMicro > 1_000_000 or maxCalls < 1 or maxCalls > 64:
    return InvalidResult

  let a = float64(aMilli) / 1000.0
  let b = float64(bMilli) / 1000.0
  let epsilon = float64(epsilonMicro) / 1_000_000.0
  ternarySearch(operation, a, b, epsilon, 1, maxCalls)
