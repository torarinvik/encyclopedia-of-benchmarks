import std/math

const MaxInputLength = 69

proc historical_var*(input: ptr UncheckedArray[float64], inputLength: csize_t,
    output: ptr UncheckedArray[float64], capacity: csize_t): int64
    {.cdecl, exportc: "historical_var".} =
  if input == nil or inputLength < csize_t(24) or inputLength > csize_t(MaxInputLength): return -1
  let length = int(inputLength)
  for i in 0 ..< length:
    if classify(input[i]) in {fcNan, fcInf, fcNegInf}: return -1
  let portfolioValue = input[0]
  let confidenceLevel = input[1]
  let timeHorizon = input[2]
  let countValue = input[3]
  if countValue < 20.0 or countValue > 64.0 or floor(countValue) != countValue: return -1
  let returnCount = int(countValue)
  if inputLength != csize_t(4 + returnCount) or portfolioValue < 100.0 or portfolioValue > 1000000.0 or
      confidenceLevel < 0.5 or confidenceLevel > 0.95 or timeHorizon < 1.0 or timeHorizon > 10.0:
    return -1
  var sortedReturns: array[64, float64]
  for i in 0 ..< returnCount:
    let value = input[4 + i]
    if value < -0.25 or value > 0.25: return -1
    var position = i
    while position > 0 and sortedReturns[position - 1] > value:
      sortedReturns[position] = sortedReturns[position - 1]
      dec position
    sortedReturns[position] = value
  let index = int(floor((1.0 - confidenceLevel) * float64(returnCount)))
  if index < 1: return -1
  let result = -sortedReturns[index - 1] * portfolioValue * sqrt(timeHorizon)
  if output == nil or capacity < csize_t(1): return -2
  output[0] = result
  1
