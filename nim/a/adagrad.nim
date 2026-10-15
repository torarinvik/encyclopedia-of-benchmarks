const MaxSteps = 256
const MaxGroups = 16
const InputScale = 1_000_000_000.0
const OutputScale = 1_000_000.0

proc adagradSqrt(value: float64): float64 =
  if value <= 0.0: return 0.0
  var root = if value > 1.0: value else: 1.0
  for _ in 0 ..< 80: root = 0.5 * (root + value / root)
  root

proc adagrad*(input: ptr UncheckedArray[int64], length: csize_t,
              output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "adagrad".} =
  if input == nil or length < 6 or length > csize_t(3 + 3 * MaxSteps): return -1
  let stepsValue = input[0]
  let learningRateValue = input[1]
  let epsilonValue = input[2]
  if stepsValue < 1 or stepsValue > MaxSteps or
      length != csize_t(3 + 3 * int(stepsValue)) or
      learningRateValue < 1 or learningRateValue > 1_000_000_000 or
      epsilonValue < 1 or epsilonValue > 10_000_000: return -1
  let steps = int(stepsValue)
  for step in 0 ..< steps:
    let id = input[3 + 3 * step]
    let parameter = input[4 + 3 * step]
    let gradient = input[5 + 3 * step]
    if id < 0 or id >= MaxGroups or parameter < -1_000_000_000_000_000'i64 or
        parameter > 1_000_000_000_000_000'i64 or gradient < -1_000_000_000_000'i64 or
        gradient > 1_000_000_000_000'i64: return -1
  if output == nil or outputCapacity < csize_t(8 * steps): return -2

  let learningRate = float64(learningRateValue) / InputScale
  let epsilon = float64(epsilonValue) / InputScale
  var accumulated: array[MaxGroups, float64]
  for step in 0 ..< steps:
    let id = int(input[3 + 3 * step])
    let parameter = float64(input[4 + 3 * step]) / InputScale
    let gradient = float64(input[5 + 3 * step]) / InputScale
    accumulated[id] += gradient * gradient
    let updated = parameter - learningRate / (adagradSqrt(accumulated[id]) + epsilon) * gradient
    let encoded = int64(updated * OutputScale)
    for byte in 0 ..< 8:
      output[8 * step + byte] = uint8((encoded shr (8 * byte)) and 255)
  int64(steps)
