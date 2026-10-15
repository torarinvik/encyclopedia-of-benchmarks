const MaxSteps = 256
const MaxParameters = 16
const InputScale = 1_000_000_000.0
const OutputScale = 1_000_000.0

proc adamSqrt(value: float64): float64 =
  if value <= 0.0: return 0.0
  var root = if value > 1.0: value else: 1.0
  for _ in 0 ..< 80: root = 0.5 * (root + value / root)
  root

proc adam*(input: ptr UncheckedArray[int64], length: csize_t,
           output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "adam".} =
  if input == nil or length < 9 or length > csize_t(7 + MaxParameters + MaxSteps * MaxParameters): return -1
  let stepsValue = input[0]
  let parameterCountValue = input[1]
  let learningRateValue = input[2]
  let beta1Value = input[3]
  let beta2Value = input[4]
  let epsilonValue = input[5]
  let weightDecayValue = input[6]
  if stepsValue < 1 or stepsValue > MaxSteps or parameterCountValue < 1 or parameterCountValue > MaxParameters:
    return -1
  let steps = int(stepsValue)
  let parameterCount = int(parameterCountValue)
  if length != csize_t(7 + parameterCount + steps * parameterCount) or
      learningRateValue < 1 or learningRateValue > 1_000_000_000 or
      beta1Value < 0 or beta1Value >= 1_000_000_000 or beta2Value < 0 or beta2Value >= 1_000_000_000 or
      epsilonValue < 1 or epsilonValue > 10_000_000 or weightDecayValue < 0 or weightDecayValue > 100_000_000:
    return -1
  for i in 0 ..< parameterCount:
    if input[7 + i] < -1_000_000_000_000_000'i64 or input[7 + i] > 1_000_000_000_000_000'i64: return -1
  let gradientStart = 7 + parameterCount
  for i in 0 ..< steps * parameterCount:
    if input[gradientStart + i] < -1_000_000_000_000'i64 or input[gradientStart + i] > 1_000_000_000_000'i64: return -1
  let outputCount = steps * parameterCount
  if output == nil or outputCapacity < csize_t(8 * outputCount): return -2

  let learningRate = float64(learningRateValue) / InputScale
  let beta1 = float64(beta1Value) / InputScale
  let beta2 = float64(beta2Value) / InputScale
  let epsilon = float64(epsilonValue) / InputScale
  let weightDecay = float64(weightDecayValue) / InputScale
  var parameters: array[MaxParameters, float64]
  var firstMoment: array[MaxParameters, float64]
  var secondMoment: array[MaxParameters, float64]
  for i in 0 ..< parameterCount: parameters[i] = float64(input[7 + i]) / InputScale
  var beta1Power = 1.0
  var beta2Power = 1.0
  for step in 0 ..< steps:
    beta1Power *= beta1
    beta2Power *= beta2
    for i in 0 ..< parameterCount:
      let gradient = float64(input[gradientStart + step * parameterCount + i]) / InputScale
      firstMoment[i] = beta1 * firstMoment[i] + (1.0 - beta1) * gradient
      secondMoment[i] = beta2 * secondMoment[i] + (1.0 - beta2) * (gradient * gradient)
      let correctedFirst = firstMoment[i] / (1.0 - beta1Power)
      let correctedSecond = secondMoment[i] / (1.0 - beta2Power)
      let updated = parameters[i] - learningRate * correctedFirst /
        (adamSqrt(correctedSecond) + epsilon) - learningRate * weightDecay * parameters[i]
      parameters[i] = updated
      let encoded = int64(updated * OutputScale)
      for byte in 0 ..< 8:
        output[8 * (step * parameterCount + i) + byte] = uint8((encoded shr (8 * byte)) and 255)
  int64(outputCount)
