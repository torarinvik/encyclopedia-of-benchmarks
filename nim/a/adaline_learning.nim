const MaxSamples = 32
const MaxFeatures = 8

proc storeI32Le(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint32](int32(value))
  for byte in 0 ..< 4:
    output[offset + byte] = uint8((bits shr (byte * 8)) and 255)

proc adaline_learning*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "adaline_learning".} =
  if input == nil or length < 5: return -1
  if input[0] < 1 or input[0] > MaxSamples or
      input[1] < 1 or input[1] > MaxFeatures or
      input[2] < 1 or input[3] < 1 or input[3] > 12 or
      input[4] < 1 or input[4] > 500: return -1

  let sampleCount = int(input[0])
  let featureCount = int(input[1])
  let etaNumerator = input[2]
  let etaShift = int(input[3])
  let maxIterations = int(input[4])
  var scale = 1'i64
  for _ in 0 ..< etaShift: scale *= 2
  if etaNumerator >= scale or length != csize_t(5 + sampleCount * (featureCount + 1)):
    return -1

  for sample in 0 ..< sampleCount:
    let row = 5 + sample * (featureCount + 1)
    for feature in 0 ..< featureCount:
      let value = input[csize_t(row + feature)]
      if value < -16 or value > 16: return -1
    let label = input[csize_t(row + featureCount)]
    if label != -1 and label != 1: return -1

  let byteCount = 4 * (1 + featureCount + 1 + sampleCount)
  if outputCapacity < csize_t(byteCount) or output == nil: return -2

  var weights: array[MaxFeatures, int64]
  for feature in 0 ..< featureCount: weights[feature] = scale
  var bias = scale
  var iterations = 0
  for _ in 0 ..< maxIterations:
    var mistakes = 0
    for sample in 0 ..< sampleCount:
      let row = 5 + sample * (featureCount + 1)
      var score = bias
      for feature in 0 ..< featureCount:
        score += input[csize_t(row + feature)] * weights[feature]
      let prediction = if score > 0: 1'i64 else: -1'i64
      let error = input[csize_t(row + featureCount)] - prediction
      if error != 0:
        inc mistakes
        let correction = etaNumerator * error
        for feature in 0 ..< featureCount:
          weights[feature] += correction * input[csize_t(row + feature)]
        bias += correction
    inc iterations
    if mistakes == 0: break

  var position = 0
  storeI32Le(output, position, int64(iterations)); position += 4
  for feature in 0 ..< featureCount:
    storeI32Le(output, position, weights[feature]); position += 4
  storeI32Le(output, position, bias); position += 4
  for sample in 0 ..< sampleCount:
    let row = 5 + sample * (featureCount + 1)
    var score = bias
    for feature in 0 ..< featureCount:
      score += input[csize_t(row + feature)] * weights[feature]
    storeI32Le(output, position, if score > 0: 1 else: -1)
    position += 4
  int64(byteCount)
