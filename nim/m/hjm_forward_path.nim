import math

const MaxSteps = 8
const MaxFactors = 3

proc hjm_forward_path*(input: ptr UncheckedArray[float64], inputLength: csize_t,
    output: ptr UncheckedArray[float64], outputCapacity: csize_t): int64 {.cdecl, exportc: "hjm_forward_path".} =
  if input == nil or inputLength < 7 or inputLength > 54: return -1
  if input[0] < 2 or input[0] > MaxSteps or input[0] != floor(input[0]): return -1
  if input[1] < 1 or input[1] > MaxFactors or input[1] != floor(input[1]): return -1
  let steps = int(input[0])
  let factors = int(input[1])
  let years = input[2]
  if years != 1.0 and years != 2.0 and years != 3.0: return -1
  if inputLength != csize_t(3 + steps + 2 * factors * (steps - 1)): return -1

  var yields: array[MaxSteps, float64]
  var vols: array[MaxFactors * (MaxSteps - 1), float64]
  var shocks: array[(MaxSteps - 1) * MaxFactors, float64]
  var forwards: array[MaxSteps, float64]
  var factorDrifts: array[MaxFactors * (MaxSteps - 1), float64]
  var totalDrifts: array[MaxSteps - 1, float64]
  var path: array[MaxSteps * MaxSteps, float64]

  var cursor = 3
  for maturity in 0 ..< steps:
    let value = input[cursor]
    inc cursor
    if not (value >= -0.05 and value <= 0.20): return -1
    yields[maturity] = value
  for factor in 0 ..< factors:
    for maturity in 0 ..< steps - 1:
      let value = input[cursor]
      inc cursor
      if not (value >= 0.0 and value <= 0.30): return -1
      vols[factor * (MaxSteps - 1) + maturity] = value
  for time in 0 ..< steps - 1:
    for factor in 0 ..< factors:
      let value = input[cursor]
      inc cursor
      if not (value >= -3.0 and value <= 3.0): return -1
      shocks[time * MaxFactors + factor] = value

  let dt = years / float64(steps)
  forwards[0] = yields[0]
  for maturity in 1 ..< steps:
    forwards[maturity] = float64(maturity + 1) * yields[maturity] - float64(maturity) * yields[maturity - 1]
  for factor in 0 ..< factors:
    let base = factor * (MaxSteps - 1)
    factorDrifts[base] = 0.5 * dt * vols[base] * vols[base]
    for maturity in 1 ..< steps - 1:
      var drift = 0.0
      for prior in 0 ..< maturity:
        drift -= factorDrifts[base + prior]
      var prefixVolatility = 0.0
      for prior in 0 .. maturity:
        prefixVolatility += vols[base + prior]
      drift += 0.5 * dt * prefixVolatility * prefixVolatility
      factorDrifts[base + maturity] = drift
  for maturity in 0 ..< steps - 1:
    for factor in 0 ..< factors:
      totalDrifts[maturity] += factorDrifts[factor * (MaxSteps - 1) + maturity]
  for maturity in 0 ..< steps:
    path[maturity] = forwards[maturity]
  let rootDt = sqrt(dt)
  for time in 1 ..< steps:
    for maturity in 0 ..< steps - time:
      var totalShock = 0.0
      for factor in 0 ..< factors:
        totalShock += vols[factor * (MaxSteps - 1) + maturity] * shocks[(time - 1) * MaxFactors + factor]
      path[time * steps + maturity] = path[(time - 1) * steps + maturity + 1] + totalDrifts[maturity] * dt + rootDt * totalShock

  let needed = steps * steps
  if output == nil or outputCapacity < csize_t(needed): return -2
  for index in 0 ..< needed: output[index] = path[index]
  int64(needed)
