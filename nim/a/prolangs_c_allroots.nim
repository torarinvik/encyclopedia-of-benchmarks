import math

const RequiredBytes = 24
const NewtonEpsilon = 5.0e-6
const MaxNewtonIterations = 40

proc absoluteValue(value: float64): float64 =
  if value < 0.0: -value else: value

proc hornerValueAndDerivative(coefficients: openArray[float64], x: float64): tuple[value, derivative: float64] =
  let degree = coefficients.len - 1
  var value = coefficients[degree]
  var slope = value
  for j in countdown(degree - 1, 1):
    value = x * value + coefficients[j]
    slope = x * slope + value
  value = x * value + coefficients[0]
  (value, slope)

proc newtonRoot(coefficients: openArray[float64], lowerBound, upperBound: float64): float64 =
  var lower = lowerBound
  var upper = upperBound
  if upper < lower: swap(lower, upper)
  var previous = lower
  var current = (lower + upper) / 2.0
  var iterations = 0
  while absoluteValue(current - previous) / absoluteValue(current) > NewtonEpsilon and
        iterations <= MaxNewtonIterations:
    previous = current
    let evaluation = hornerValueAndDerivative(coefficients, current)
    current -= evaluation.value / evaluation.derivative
    inc iterations
  current

proc storeF64Le(output: ptr UncheckedArray[uint8], offset: int, value: float64) =
  let bits = cast[uint64](value)
  for i in 0 ..< 8:
    output[offset + i] = uint8((bits shr (8 * i)) and 255'u64)

proc solve(staged: ptr UncheckedArray[uint8]) =
  let original = [4.0, -4.0, -1.0, 1.0]
  let coefficients = original
  var upper = 0.0
  for coefficient in coefficients: upper += absoluteValue(coefficient)
  upper /= absoluteValue(coefficients[3])
  let lower = -upper - 1.0

  let firstRoot = newtonRoot(coefficients, lower, upper)
  var deflated: array[3, float64]
  deflated[2] = coefficients[3]
  for i in countdown(1, 0): deflated[i] = deflated[i + 1] * firstRoot + coefficients[i + 1]

  let discriminant = deflated[1] * deflated[1] - 4.0 * deflated[2] * deflated[0]
  let plusRoot = (-deflated[1] + sqrt(discriminant)) / (2.0 * deflated[2])
  let minusRoot = (-deflated[1] - sqrt(discriminant)) / (2.0 * deflated[2])
  let refinedPlus = newtonRoot(original, plusRoot - 0.5, plusRoot + 0.5)
  let refinedMinus = newtonRoot(original, minusRoot - 0.5, minusRoot + 0.5)
  storeF64Le(staged, 0, firstRoot)
  storeF64Le(staged, 8, refinedPlus)
  storeF64Le(staged, 16, refinedMinus)

proc prolangs_c_allroots*(values: ptr UncheckedArray[int64], length: csize_t,
                          output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "prolangs_c_allroots".} =
  if values == nil or length != 4: return -1
  if values[0] != 4 or values[1] != -4 or values[2] != -1 or values[3] != 1: return -1
  if output == nil or outputCapacity < csize_t(RequiredBytes): return -2
  var staged: array[RequiredBytes, uint8]
  solve(cast[ptr UncheckedArray[uint8]](addr staged[0]))
  for i in 0 ..< RequiredBytes: output[i] = staged[i]
  int64(RequiredBytes)
