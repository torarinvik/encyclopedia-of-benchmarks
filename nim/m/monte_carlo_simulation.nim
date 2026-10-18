import std/math

const MaxParseableInputLength = 520
const MaxSimulations = 32

proc allowedMaturity(value: float64): bool =
  value == 0.25 or value == 0.5 or value == 1.0 or value == 2.0

proc allowedStepCount(value: float64): bool =
  value == 1.0 or value == 2.0 or value == 4.0 or value == 8.0 or value == 16.0

proc finiteValue(value: float64): bool =
  classify(value) notin {fcNan, fcInf, fcNegInf}

proc monte_carlo_simulation*(input: ptr UncheckedArray[float64], inputLength: csize_t,
    output: ptr UncheckedArray[float64], outputCapacity: csize_t): int64
    {.cdecl, exportc: "monte_carlo_simulation".} =
  if input == nil or inputLength < 7 or inputLength > MaxParseableInputLength.csize_t:
    return -1
  for index in 0 ..< int(inputLength):
    if not finiteValue(input[index]): return -1

  let s0 = input[0]
  let strike = input[1]
  let rate = input[2]
  let volatility = input[3]
  let maturity = input[4]
  let stepValue = input[5]
  let simulationValue = input[6]
  if s0 < 1.0 or s0 > 1000.0 or strike < 0.0 or strike > 2000.0 or
      rate < -0.25 or rate > 0.25 or volatility < 0.0 or volatility > 0.5 or
      not allowedMaturity(maturity) or not allowedStepCount(stepValue) or
      simulationValue < 1.0 or simulationValue > MaxSimulations.float64 or
      float64(int64(simulationValue)) != simulationValue:
    return -1

  let steps = int(stepValue)
  let simulations = int(simulationValue)
  if inputLength != csize_t(7 + steps * simulations): return -1
  for index in 7 ..< int(inputLength):
    if input[index] < -3.0 or input[index] > 3.0: return -1

  let dt = maturity / float64(steps)
  let sqrtDt = sqrt(dt)
  let driftRate = rate - 0.5 * (volatility * volatility)
  let drift = driftRate * maturity
  var payoffs: array[MaxSimulations, float64]
  for simulation in 0 ..< simulations:
    var brownian = 0.0
    let offset = 7 + simulation * steps
    for step in 0 ..< steps:
      brownian += sqrtDt * input[offset + step]
    let exponent = drift + volatility * brownian
    let terminalPrice = s0 * exp(exponent)
    let difference = terminalPrice - strike
    payoffs[simulation] = if difference > 0.0: difference else: 0.0

  var total = 0.0
  for simulation in 0 ..< simulations:
    total += payoffs[simulation]
  let optionPrice = (total / float64(simulations)) * exp(-rate * maturity)
  if not finiteValue(optionPrice): return -1
  if output == nil or outputCapacity < 1: return -2
  output[0] = optionPrice
  return 1
