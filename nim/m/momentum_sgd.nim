import std/math

const
  MaxGroupCount = 8
  MaxVectorLength = 16
  MaxGroupVectorElements = 32
  MaxCallCount = 8
  MaxParseableInputLength = 270

proc momentum_sgd*(input: ptr UncheckedArray[float64], inputLength: csize_t,
    output: ptr UncheckedArray[float64], outputCapacity: csize_t): int64
    {.cdecl, exportc: "momentum_sgd".} =
  if input == nil or inputLength < 5 or inputLength > MaxParseableInputLength.csize_t:
    return -1
  let groupValue = input[0]
  let vectorValue = input[1]
  let callsValue = input[2]
  if classify(groupValue) == fcNan or groupValue < 1.0 or groupValue > float64(MaxGroupCount):
    return -1
  if classify(vectorValue) == fcNan or vectorValue < 1.0 or vectorValue > float64(MaxVectorLength):
    return -1
  if classify(callsValue) == fcNan or callsValue < 1.0 or callsValue > float64(MaxCallCount):
    return -1
  let groupCount = int(groupValue)
  let vectorLength = int(vectorValue)
  let callCount = int(callsValue)
  if groupValue != float64(groupCount) or vectorValue != float64(vectorLength) or callsValue != float64(callCount):
    return -1
  if groupCount * vectorLength > MaxGroupVectorElements or callCount < groupCount:
    return -1
  if inputLength != (5 + callCount * (1 + 2 * vectorLength)).csize_t:
    return -1

  let learningRate = input[3]
  let momentum = input[4]
  if classify(learningRate) == fcNan or learningRate < 1e-6 or learningRate > 1.0:
    return -1
  if classify(momentum) == fcNan or momentum < 0.0 or momentum > 0.99:
    return -1

  var ids: array[MaxCallCount, int]
  var eventParams: array[MaxCallCount * MaxVectorLength, float64]
  var eventGradients: array[MaxCallCount * MaxVectorLength, float64]
  var seen: array[MaxGroupCount, bool]
  var cursor = 5
  for event in 0 ..< callCount:
    let idValue = input[cursor]
    if classify(idValue) == fcNan or idValue < 0.0 or idValue >= float64(groupCount):
      return -1
    let id = int(idValue)
    if idValue != float64(id):
      return -1
    ids[event] = id
    seen[id] = true
    inc cursor
    for component in 0 ..< vectorLength:
      let value = input[cursor + component]
      if classify(value) == fcNan or value < -1000.0 or value > 1000.0:
        return -1
      eventParams[event * vectorLength + component] = value
    cursor += vectorLength
    for component in 0 ..< vectorLength:
      let value = input[cursor + component]
      if classify(value) == fcNan or value < -1000.0 or value > 1000.0:
        return -1
      eventGradients[event * vectorLength + component] = value
    cursor += vectorLength
  for id in 0 ..< groupCount:
    if not seen[id]:
      return -1
  let outputElements = 2 * groupCount * vectorLength
  if output == nil or outputCapacity < outputElements.csize_t:
    return -2

  var velocities: array[MaxGroupVectorElements, float64]
  var lastParams: array[MaxGroupVectorElements, float64]
  for event in 0 ..< callCount:
    let id = ids[event]
    for component in 0 ..< vectorLength:
      let stateIndex = id * vectorLength + component
      let eventIndex = event * vectorLength + component
      let updatedVelocity = momentum * velocities[stateIndex] - learningRate * eventGradients[eventIndex]
      velocities[stateIndex] = updatedVelocity
      lastParams[stateIndex] = eventParams[eventIndex] + updatedVelocity
  for index in 0 ..< groupCount * vectorLength:
    output[index] = lastParams[index]
    output[groupCount * vectorLength + index] = velocities[index]
  int64(outputElements)
