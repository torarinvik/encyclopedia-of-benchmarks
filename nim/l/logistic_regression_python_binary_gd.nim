import std/math

const MaxSamples = 32
const MaxFeatures = 8
const QScale = 1_000_000.0

proc putF64(output: ptr UncheckedArray[uint8], offset: int, value: float64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8((bits shr (8 * byte)) and 0xFF'u64)

proc logistic_regression_python_binary_gd*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64 {.cdecl, exportc: "logistic_regression_python_binary_gd".} =
  if input.isNil or length < 4: return -1
  let mValue = input[0]
  let dValue = input[1]
  let epochsValue = input[2]
  let alphaQ = input[3]
  if mValue < 1 or mValue > MaxSamples or dValue < 1 or dValue > MaxFeatures
      or epochsValue < 0 or epochsValue > 128 or alphaQ < 1 or alphaQ > 100000: return -1
  let m = int(mValue)
  let d = int(dValue)
  let epochs = int(epochsValue)
  if int(length) != 4 + m * d + m: return -1
  let labelsOffset = 4 + m * d
  for index in 0 ..< m * d:
    if input[4 + index] < -1_000_000 or input[4 + index] > 1_000_000: return -1
  for sample in 0 ..< m:
    if input[labelsOffset + sample] != 0 and input[labelsOffset + sample] != 1: return -1
  let required = d * 8
  if output.isNil or int(capacity) < required: return -2

  var theta: array[MaxFeatures, float64]
  var nextTheta: array[MaxFeatures, float64]
  var errors: array[MaxSamples, float64]
  let alpha = float64(alphaQ) / QScale
  for epoch in 0 ..< epochs:
    for sample in 0 ..< m:
      var score = 0.0
      for feature in 0 ..< d:
        let x = float64(input[4 + sample * d + feature]) / QScale
        score += x * theta[feature]
      let prediction = 1.0 / (1.0 + exp(-score))
      errors[sample] = prediction - float64(input[labelsOffset + sample])
    for feature in 0 ..< d:
      var gradient = 0.0
      for sample in 0 ..< m:
        let x = float64(input[4 + sample * d + feature]) / QScale
        gradient += x * errors[sample]
      gradient /= float64(m)
      nextTheta[feature] = theta[feature] - alpha * gradient
    for feature in 0 ..< d:
      theta[feature] = nextTheta[feature]
  for feature in 0 ..< d:
    putF64(output, feature * 8, theta[feature])
  int64(required)
