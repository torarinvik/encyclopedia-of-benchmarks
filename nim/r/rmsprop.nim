import std/math

const
  MaxVectorLength = 32
  MaxParseableInputLength = 102

proc rmsprop*(input: ptr UncheckedArray[float64], inputLength: csize_t,
    output: ptr UncheckedArray[float64], outputCapacity: csize_t): int64
    {.cdecl, exportc: "rmsprop".} =
  if input == nil or inputLength < 5 or inputLength > MaxParseableInputLength.csize_t:
    return -1
  let countValue = input[0]
  if classify(countValue) == fcNan or countValue < 0.0 or countValue > float64(MaxVectorLength):
    return -1
  let count = int(countValue)
  if countValue != float64(count):
    return -1
  let modeValue = input[1]
  if modeValue != 0.0 and modeValue != 1.0:
    return -1
  let mode = int(modeValue)
  let expectedLength = 5 + 2 * count + (if mode == 1: count else: 0)
  if inputLength != expectedLength.csize_t:
    return -1

  let learningRate = input[2]
  let rho = input[3]
  let epsilon = input[4]
  if classify(learningRate) == fcNan or learningRate < 1e-6 or learningRate > 1.0:
    return -1
  if classify(rho) == fcNan or rho < 0.0 or rho > 0.99:
    return -1
  if classify(epsilon) == fcNan or epsilon < 1e-8 or epsilon > 1.0:
    return -1

  var params: array[MaxVectorLength, float64]
  var gradients: array[MaxVectorLength, float64]
  var movingAvg: array[MaxVectorLength, float64]
  for index in 0 ..< count:
    let param = input[5 + index]
    let gradient = input[5 + count + index]
    if classify(param) == fcNan or param < -100.0 or param > 100.0:
      return -1
    if classify(gradient) == fcNan or gradient < -100.0 or gradient > 100.0:
      return -1
    params[index] = param
    gradients[index] = gradient
    movingAvg[index] = 0.0
  if mode == 1:
    for index in 0 ..< count:
      let value = input[5 + 2 * count + index]
      if classify(value) == fcNan or value < 0.0 or value > 10000.0:
        return -1
      movingAvg[index] = value
  if output == nil or outputCapacity < (2 * count).csize_t:
    return -2

  for index in 0 ..< count:
    let gradient = gradients[index]
    let updatedAvg = rho * movingAvg[index] + (1.0 - rho) * (gradient * gradient)
    movingAvg[index] = updatedAvg
    params[index] = params[index] - (learningRate / sqrt(updatedAvg + epsilon)) * gradient
  for index in 0 ..< count:
    output[index] = params[index]
    output[count + index] = movingAvg[index]
  int64(2 * count)
