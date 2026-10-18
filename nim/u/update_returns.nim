import std/math

const MinReturns = 2
const MaxReturns = 60
const MaxInputLength = 62
const MaxOutputLength = 63
const Z95 = 1.6448536269514722

proc finiteValue(value: float64): bool =
  let kind = classify(value)
  kind != fcNan and kind != fcInf and kind != fcNegInf

proc update_returns*(input: ptr UncheckedArray[float64], inputLength: csize_t,
    output: ptr UncheckedArray[float64], outputCapacity: csize_t): int64
    {.cdecl, exportc: "update_returns".} =
  if input.isNil or inputLength < csize_t(1 + MinReturns) or inputLength > csize_t(MaxInputLength):
    return -1
  for index in 0 ..< int(inputLength):
    if not finiteValue(input[index]): return -1

  let rawCount = input[0]
  if rawCount < float64(MinReturns) or rawCount > float64(MaxReturns) or floor(rawCount) != rawCount:
    return -1
  let count = int(rawCount)
  if inputLength != csize_t(count + 1): return -1

  var returns: array[MaxReturns, float64]
  var total = 0.0
  for index in 0 ..< count:
    let value = input[index + 1]
    if value < -0.25 or value > 0.25: return -1
    returns[index] = value
    total += value

  let mean = total / float64(count)
  if not finiteValue(mean): return -1
  var squaredDeviations = 0.0
  for index in 0 ..< count:
    let difference = returns[index] - mean
    squaredDeviations += difference * difference
  let sampleSd = sqrt(squaredDeviations / float64(count - 1))
  if not finiteValue(sampleSd) or sampleSd == 0.0: return -1
  let parametricVar = 100000.0 * (Z95 * sampleSd - mean)
  if not finiteValue(parametricVar): return -1

  var staged: array[MaxOutputLength, float64]
  for index in 0 ..< count:
    staged[index] = returns[index]
  staged[count] = mean
  staged[count + 1] = sampleSd
  staged[count + 2] = parametricVar
  let resultLength = count + 3
  if output.isNil or outputCapacity < csize_t(resultLength): return -2
  for index in 0 ..< resultLength:
    output[index] = staged[index]
  int64(resultLength)
