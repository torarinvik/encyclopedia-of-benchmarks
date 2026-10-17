import std/math

const
  MaxSampleCount = 32
  MaxParseableInputLength = 38

proc soboleva_modified_hyperbolic_tangent*(input: ptr UncheckedArray[float64], inputLength: csize_t,
    output: ptr UncheckedArray[float64], outputCapacity: csize_t): int64 {.cdecl, exportc: "soboleva_modified_hyperbolic_tangent".} =
  if input == nil or inputLength < 5 or inputLength > MaxParseableInputLength.csize_t:
    return -1
  let countValue = input[0]
  if countValue != countValue or countValue < 1.0 or countValue > float64(MaxSampleCount) or countValue != floor(countValue):
    return -1
  let count = int(countValue)
  if inputLength != (5 + count).csize_t:
    return -1

  let a = input[1]
  let b = input[2]
  let c = input[3]
  let d = input[4]
  for coefficient in [a, b, c, d]:
    if coefficient != coefficient or coefficient < -2.0 or coefficient > 2.0:
      return -1
  for index in 0 ..< count:
    let sample = input[index + 5]
    if sample != sample or sample < -20.0 or sample > 20.0:
      return -1
  if output == nil or outputCapacity < count.csize_t:
    return -2

  for index in 0 ..< count:
    let sample = input[index + 5]
    let expAx = exp(a * sample)
    let expNegBx = exp((-b) * sample)
    let numerator = expAx - expNegBx
    let expCx = exp(c * sample)
    let expNegDx = exp((-d) * sample)
    let denominator = expCx + expNegDx
    output[index] = numerator / denominator
  return int64(count)
