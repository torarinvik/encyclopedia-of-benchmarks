const MAX_SUPPORT_LENGTH = 4
const MAX_PARSEABLE_INPUT_LENGTH = 20
const MAX_OUTPUT_ELEMENTS = 48

proc joint_probability_distribution*(input: ptr UncheckedArray[float64], inputLen: csize_t,
                                    output: ptr UncheckedArray[float64], outputCapacity: csize_t): int64
    {.cdecl, exportc: "joint_probability_distribution".} =
  if input.isNil or inputLen < csize_t(2) or inputLen > csize_t(MAX_PARSEABLE_INPUT_LENGTH): return -1
  let nxValue = input[0]
  let nyValue = input[1]
  if nxValue != nxValue or nyValue != nyValue or
      nxValue < 1.0 or nxValue > float64(MAX_SUPPORT_LENGTH) or
      nyValue < 1.0 or nyValue > float64(MAX_SUPPORT_LENGTH): return -1
  let nx = int(nxValue)
  let ny = int(nyValue)
  if float64(nx) != nxValue or float64(ny) != nyValue: return -1
  if inputLen != csize_t(2 + 2 * nx + 2 * ny): return -1

  let xStart = 2
  let yStart = xStart + nx
  let xProbabilityStart = yStart + ny
  let yProbabilityStart = xProbabilityStart + nx
  var xValues: array[MAX_SUPPORT_LENGTH, int64]
  var yValues: array[MAX_SUPPORT_LENGTH, int64]
  var xProbabilities: array[MAX_SUPPORT_LENGTH, float64]
  var yProbabilities: array[MAX_SUPPORT_LENGTH, float64]

  for index in 0 ..< nx:
    let raw = input[xStart + index]
    if raw != raw or raw < -1000.0 or raw > 1000.0: return -1
    xValues[index] = int64(raw)
    if float64(xValues[index]) != raw: return -1
    let probability = input[xProbabilityStart + index]
    if probability != probability or probability < -1_000_000.0 or probability > 1_000_000.0: return -1
    xProbabilities[index] = probability
    for previous in 0 ..< index:
      if xValues[previous] == xValues[index]: return -1

  for index in 0 ..< ny:
    let raw = input[yStart + index]
    if raw != raw or raw < -1000.0 or raw > 1000.0: return -1
    yValues[index] = int64(raw)
    if float64(yValues[index]) != raw: return -1
    let probability = input[yProbabilityStart + index]
    if probability != probability or probability < -1_000_000.0 or probability > 1_000_000.0: return -1
    yProbabilities[index] = probability
    for previous in 0 ..< index:
      if yValues[previous] == yValues[index]: return -1

  let required = 3 * nx * ny
  if required > MAX_OUTPUT_ELEMENTS: return -1
  if output.isNil or outputCapacity < csize_t(required): return -2
  var position = 0
  for xIndex in 0 ..< nx:
    for yIndex in 0 ..< ny:
      output[position] = float64(xValues[xIndex])
      output[position + 1] = float64(yValues[yIndex])
      output[position + 2] = xProbabilities[xIndex] * yProbabilities[yIndex]
      position += 3
  int64(required)
