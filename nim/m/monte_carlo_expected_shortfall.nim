import std/math

const
  MinReturns = 20
  MaxReturns = 64
  MinSimulations = 20
  MaxSimulations = 128
  MaxValidInputLength = 197
  MaxParseableInputLength = 198

proc finiteValue(value: float64): bool =
  classify(value) notin {fcNan, fcInf, fcNegInf}

proc monte_carlo_expected_shortfall*(input: ptr UncheckedArray[float64], inputLength: csize_t,
    output: ptr UncheckedArray[float64], outputCapacity: csize_t): int64
    {.cdecl, exportc: "monte_carlo_expected_shortfall".} =
  if input == nil or inputLength < 45 or inputLength > MaxParseableInputLength.csize_t:
    return -1
  for index in 0 ..< int(inputLength):
    if not finiteValue(input[index]): return -1

  let portfolio = input[0]
  let confidence = input[1]
  let horizon = input[2]
  let simulationValue = input[3]
  let returnCountValue = input[4]
  if portfolio < 100.0 or portfolio > 1000000.0 or
      confidence < 0.5 or confidence > 0.95 or
      horizon < 1.0 or horizon > 10.0 or
      simulationValue < float64(MinSimulations) or simulationValue > float64(MaxSimulations) or
      returnCountValue < float64(MinReturns) or returnCountValue > float64(MaxReturns):
    return -1
  let simulationCount = int(simulationValue)
  let returnCount = int(returnCountValue)
  if float64(simulationCount) != simulationValue or float64(returnCount) != returnCountValue:
    return -1
  if int(inputLength) != 5 + returnCount + simulationCount or int(inputLength) > MaxValidInputLength:
    return -1

  var returns: array[MaxReturns, float64]
  var simulated: array[MaxSimulations, float64]
  var sum = 0.0
  for index in 0 ..< returnCount:
    let value = input[5 + index]
    if value < -0.25 or value > 0.25: return -1
    returns[index] = value
    sum += value
  for index in 0 ..< simulationCount:
    let z = input[5 + returnCount + index]
    if z < -3.0 or z > 3.0: return -1
    simulated[index] = z

  let mean = sum / float64(returnCount)
  var squaredDeviation = 0.0
  for value in returns[0 ..< returnCount]:
    let delta = value - mean
    squaredDeviation += delta * delta
  let volatility = sqrt(squaredDeviation / float64(returnCount - 1))
  if not finiteValue(volatility) or volatility == 0.0: return -1
  for index in 0 ..< simulationCount:
    simulated[index] = mean + volatility * simulated[index]
  for index in 1 ..< simulationCount:
    let value = simulated[index]
    var position = index
    while position > 0 and simulated[position - 1] > value:
      simulated[position] = simulated[position - 1]
      dec position
    simulated[position] = value

  let tailValue = floor((1.0 - confidence) * float64(simulationCount))
  if tailValue < 1.0 or tailValue > float64(simulationCount): return -1
  let tailCount = int(tailValue)
  var tailSum = 0.0
  for index in 0 ..< tailCount:
    tailSum += simulated[index]
  let metric = -(tailSum / float64(tailCount)) * portfolio * sqrt(horizon)
  if not finiteValue(metric): return -1
  if output == nil or outputCapacity < 1: return -2
  output[0] = metric
  return 1
