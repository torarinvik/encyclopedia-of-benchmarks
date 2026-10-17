import std/math

const MinSampleCount = 2
const MaxSampleCount = 32
const MaxInputLength = 66

proc linearregressionrawr*(input: ptr UncheckedArray[float64], inputLength: csize_t,
    output: ptr UncheckedArray[float64], outputCapacity: csize_t): int64
    {.cdecl, exportc: "linearregressionrawr".} =
  if input == nil or inputLength < 1 or inputLength > MaxInputLength.csize_t: return -1
  let nValue = input[0]
  if classify(nValue) in {fcNan, fcInf, fcNegInf} or nValue < MinSampleCount.float64 or
      nValue > MaxSampleCount.float64 or floor(nValue) != nValue: return -1
  let n = int(nValue)
  if inputLength != csize_t(1 + 2 * n): return -1

  var predictors, responses: array[MaxSampleCount, int64]
  var predictorSum = 0'i64
  var responseSum = 0'i64
  var crossSum = 0'i64
  var squareSum = 0'i64
  for index in 0 ..< n:
    let value = input[1 + index]
    if classify(value) in {fcNan, fcInf, fcNegInf} or value < -4.0 or value > 4.0 or
        floor(value) != value: return -1
    predictors[index] = int64(value)
    predictorSum += predictors[index]
  for index in 0 ..< n:
    let value = input[1 + n + index]
    if classify(value) in {fcNan, fcInf, fcNegInf} or value < -16.0 or value > 16.0 or
        floor(value) != value: return -1
    responses[index] = int64(value)
    responseSum += responses[index]
    crossSum += predictors[index] * responses[index]
    squareSum += predictors[index] * predictors[index]
  if predictorSum != 0: return -1
  var allEqual = true
  for index in 1 ..< n:
    if predictors[index] != predictors[0]: allEqual = false
  if allEqual: return -1

  if output == nil or outputCapacity < 2: return -2
  output[0] = float64(responseSum) / float64(n)
  output[1] = float64(crossSum) / float64(squareSum)
  2
