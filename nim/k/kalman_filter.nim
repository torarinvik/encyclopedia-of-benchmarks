import std/math

const MaxSteps = 12
const MaxParseableLength = 64
const Scale = 1_000_000.0

proc kalman_filter*(input: ptr UncheckedArray[float64], length: csize_t,
    output: ptr UncheckedArray[float64], outputCapacity: csize_t): int64
    {.cdecl, exportc: "kalman_filter".} =
  if input == nil or length < 5 or length > csize_t(MaxParseableLength): return -1
  for index in 0 ..< int(length):
    let valueClass = classify(input[index])
    if valueClass == fcInf or valueClass == fcNegInf or valueClass == fcNan or
        floor(input[index]) != input[index]: return -1
  let rawSteps = input[4]
  if rawSteps < 1.0 or rawSteps > float64(MaxSteps): return -1
  let steps = int(rawSteps)
  if length != csize_t(5 + steps): return -1
  if input[0] < -1_000_000_000.0 or input[0] > 1_000_000_000.0 or
      input[1] < 0.0 or input[1] > 1_000_000_000_000.0 or
      input[2] < 0.0 or input[2] > 1_000_000_000_000.0 or
      input[3] < 1.0 or input[3] > 1_000_000_000_000.0: return -1
  for index in 0 ..< steps:
    let measurement = input[5 + index]
    if measurement < -1_000_000_000.0 or measurement > 1_000_000_000.0: return -1

  let required = 3 * steps
  if output == nil or outputCapacity < csize_t(required): return -2
  var estimate = input[0] / Scale
  var covariance = input[1] / Scale
  let processNoise = input[2] / Scale
  let measurementNoise = input[3] / Scale
  for step in 0 ..< steps:
    let measurement = input[5 + step] / Scale
    estimate += 0.0
    covariance += processNoise
    let innovationVariance = covariance + measurementNoise
    let gain = covariance / innovationVariance
    estimate += gain * (measurement - estimate)
    covariance = covariance * measurementNoise / innovationVariance
    output[3 * step] = estimate
    output[3 * step + 1] = covariance
    output[3 * step + 2] = gain
  int64(required)
