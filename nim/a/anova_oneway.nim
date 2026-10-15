import math

const MaxObservations = 128
const MaxGroups = 8
const InvalidResult = -1.0e300

proc safeDenominator(value: float64): float64 =
  if abs(value) >= 1.0e-300: return value
  if value < 0.0: return -1.0e-300
  1.0e-300

proc logGammaLanczos(value: float64): float64 =
  let z = value - 1.0
  var total = 0.99999999999980993
  total += 676.5203681218851 / (z + 1.0)
  total -= 1259.1392167224028 / (z + 2.0)
  total += 771.32342877765313 / (z + 3.0)
  total -= 176.61502916214059 / (z + 4.0)
  total += 12.507343278686905 / (z + 5.0)
  total -= 0.13857109526572012 / (z + 6.0)
  total += 9.9843695780195716e-6 / (z + 7.0)
  total += 1.5056327351493116e-7 / (z + 8.0)
  let t = z + 7.5
  0.91893853320467274178 + (z + 0.5) * ln(t) - t + ln(total)

proc betaFraction(a, b, x: float64): float64 =
  let qab = a + b
  let qap = a + 1.0
  let qam = a - 1.0
  var c = 1.0
  var d = safeDenominator(1.0 - qab * x / qap)
  d = 1.0 / d
  var result = d
  for m in 1 .. 200:
    let md = float64(m)
    let m2 = 2.0 * md
    var coefficient = md * (b - md) * x / ((qam + m2) * (a + m2))
    d = safeDenominator(1.0 + coefficient * d)
    c = safeDenominator(1.0 + coefficient / c)
    d = 1.0 / d
    result *= d * c
    coefficient = -(a + md) * (qab + md) * x / ((a + m2) * (qap + m2))
    d = safeDenominator(1.0 + coefficient * d)
    c = safeDenominator(1.0 + coefficient / c)
    d = 1.0 / d
    let change = d * c
    result *= change
    if abs(change - 1.0) <= 3.0e-14: break
  result

proc regularizedBeta(x, a, b: float64): float64 =
  if x <= 0.0: return 0.0
  if x >= 1.0: return 1.0
  let front = exp(a * ln(x) + b * ln(1.0 - x) +
                  logGammaLanczos(a + b) - logGammaLanczos(a) - logGammaLanczos(b))
  if x < (a + 1.0) / (a + b + 2.0): return front * betaFraction(a, b, x) / a
  1.0 - front * betaFraction(b, a, 1.0 - x) / b

proc anova_oneway*(input: ptr UncheckedArray[int64], length: csize_t): float64
    {.cdecl, exportc: "anova_oneway".} =
  if input == nil or length < 3: return InvalidResult
  let statistic = input[0]
  let observationCount = input[1]
  let groupCount = input[2]
  if statistic < 0 or statistic > 7 or observationCount <= groupCount or observationCount > MaxObservations or
      groupCount < 2 or groupCount > MaxGroups or length != 3 + 2 * csize_t(observationCount): return InvalidResult

  var groupSums: array[MaxGroups, float64]
  var groupMeans: array[MaxGroups, float64]
  var groupSizes: array[MaxGroups, int64]
  var labels: array[MaxObservations, int64]
  var total = 0.0
  for i in 0 ..< int(observationCount):
    let value = input[3 + i]
    let group = input[3 + int(observationCount) + i]
    if value < -1_000_000 or value > 1_000_000 or group < 0 or group >= groupCount: return InvalidResult
    labels[i] = group
    groupSums[int(group)] += float64(value)
    inc groupSizes[int(group)]
    total += float64(value)
  for group in 0 ..< int(groupCount):
    if groupSizes[group] == 0: return InvalidResult
    groupMeans[group] = groupSums[group] / float64(groupSizes[group])
  let grandMean = total / float64(observationCount)
  var ssBetween = 0.0
  for group in 0 ..< int(groupCount):
    let difference = groupMeans[group] - grandMean
    ssBetween += float64(groupSizes[group]) * difference * difference
  var ssWithin = 0.0
  for group in 0 ..< int(groupCount):
    for i in 0 ..< int(observationCount):
      if labels[i] == int64(group):
        let difference = float64(input[3 + i]) - groupMeans[group]
        ssWithin += difference * difference
  if ssWithin <= 0.0: return InvalidResult

  let dfBetween = float64(groupCount - 1)
  let dfWithin = float64(observationCount - groupCount)
  let msBetween = ssBetween / dfBetween
  let msWithin = ssWithin / dfWithin
  let fStatistic = msBetween / msWithin
  let betaX = dfWithin / (dfWithin + dfBetween * fStatistic)
  let pValue = regularizedBeta(betaX, dfWithin / 2.0, dfBetween / 2.0)
  let outputs = [dfBetween, dfWithin, ssBetween, ssWithin, msBetween, msWithin, fStatistic, pValue]
  outputs[int(statistic)]
