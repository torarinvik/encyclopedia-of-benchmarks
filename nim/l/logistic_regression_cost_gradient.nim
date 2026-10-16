import std/math

const MaxSamples = 64
const MaxFeatures = 8
const QScale = 1_000_000.0

proc putF64(output: ptr UncheckedArray[uint8], offset: int, value: float64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8((bits shr (8 * byte)) and 0xFF'u64)

proc logistic_regression_cost_gradient*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64 {.cdecl, exportc: "logistic_regression_cost_gradient".} =
  if input.isNil or length < 2: return -1
  let mValue = input[0]
  let dValue = input[1]
  if mValue < 1 or mValue > MaxSamples or dValue < 1 or dValue > MaxFeatures: return -1
  let m = int(mValue)
  let d = int(dValue)
  let featuresOffset = 2
  let thetaOffset = featuresOffset + m * d
  let labelsOffset = thetaOffset + d
  if int(length) != labelsOffset + m: return -1
  for index in 0 ..< m * d:
    if input[featuresOffset + index] < -1_000_000 or input[featuresOffset + index] > 1_000_000: return -1
  for feature in 0 ..< d:
    if input[thetaOffset + feature] < -1_000_000 or input[thetaOffset + feature] > 1_000_000: return -1
  for sample in 0 ..< m:
    if input[labelsOffset + sample] != 0 and input[labelsOffset + sample] != 1: return -1
  let required = (d + 1) * 8
  if output.isNil or int(capacity) < required: return -2

  var loss = 0.0
  var gradient: array[MaxFeatures, float64]
  for sample in 0 ..< m:
    var score = 0.0
    for feature in 0 ..< d:
      let x = float64(input[featuresOffset + sample * d + feature]) / QScale
      let theta = float64(input[thetaOffset + feature]) / QScale
      score += x * theta
    let probability = 1.0 / (1.0 + exp(-score))
    let label = float64(input[labelsOffset + sample])
    loss += -label * ln(probability) - (1.0 - label) * ln(1.0 - probability)
    let error = probability - label
    for feature in 0 ..< d:
      let x = float64(input[featuresOffset + sample * d + feature]) / QScale
      gradient[feature] += error * x
  putF64(output, 0, loss / float64(m))
  for feature in 0 ..< d:
    putF64(output, (feature + 1) * 8, gradient[feature] / float64(m))
  int64(required)
