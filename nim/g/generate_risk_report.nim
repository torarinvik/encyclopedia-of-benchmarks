import std/math

const MaxInputLength = 69
const PiValue = 3.14159265358979323846264338327950288

proc normalQuantile(probability: float64): float64 =
  let q = probability - 0.5
  if abs(q) <= 0.425:
    let r = 0.180625 - q * q
    var numerator = 2509.0809287301226727
    for coefficient in [33430.575583588128105, 67265.770927008700853,
        45921.953931549871457, 13731.693765509461125, 1971.5909503065514427,
        133.14166789178437745, 3.387132872796366608]:
      numerator = numerator * r + coefficient
    var denominator = 5226.495278852854561
    for coefficient in [28729.085735721942674, 39307.89580009271061,
        21213.794301586595867, 5394.1960214247511077, 687.1870074920579083,
        42.313330701600911252, 1.0]:
      denominator = denominator * r + coefficient
    return q * numerator / denominator
  var r = sqrt(-ln(1.0 - probability)) - 1.6
  var numerator = 0.00077454501427834140764
  for coefficient in [0.0227238449892691845833, 0.24178072517745061177,
      1.27045825245236838258, 3.64784832476320460504, 5.7694972214606914055,
      4.6303378461565452959, 1.42343711074968357734]:
    numerator = numerator * r + coefficient
  var denominator = 1.05075007164441684324e-9
  for coefficient in [0.0005475938084995344946, 0.0151986665636164571966,
      0.14810397642748007459, 0.68976733498510000455, 1.6763848301838038494,
      2.05319162663775882187, 1.0]:
    denominator = denominator * r + coefficient
  numerator / denominator

proc generate_risk_report*(input: ptr UncheckedArray[float64], inputLength: csize_t,
    output: ptr UncheckedArray[float64], capacity: csize_t): int64
    {.cdecl, exportc: "generate_risk_report".} =
  if input == nil or inputLength < csize_t(24) or inputLength > csize_t(MaxInputLength): return -1
  let length = int(inputLength)
  for i in 0 ..< length:
    if classify(input[i]) in {fcNan, fcInf, fcNegInf}: return -1
  let portfolio = input[0]
  let confidence = input[1]
  let horizon = input[2]
  let countValue = input[3]
  if countValue < 20.0 or countValue > 64.0 or floor(countValue) != countValue: return -1
  let count = int(countValue)
  if inputLength != csize_t(4 + count) or portfolio < 100.0 or portfolio > 1000000.0 or
      confidence < 0.5 or confidence > 0.95 or horizon < 1.0 or horizon > 10.0: return -1
  var returns: array[64, float64]
  var sum = 0.0
  for i in 0 ..< count:
    let value = input[4 + i]
    if value < -0.25 or value > 0.25: return -1
    returns[i] = value
    sum += value
  let mean = sum / float64(count)
  var squaredDeviations = 0.0
  for i in 0 ..< count:
    let difference = returns[i] - mean
    squaredDeviations += difference * difference
  let sampleSd = sqrt(squaredDeviations / float64(count - 1))
  if sampleSd == 0.0: return -1
  let tailCount = int(floor((1.0 - confidence) * float64(count)))
  if tailCount < 1: return -1
  for i in 1 ..< count:
    let value = returns[i]
    var position = i
    while position > 0 and returns[position - 1] > value:
      returns[position] = returns[position - 1]
      dec position
    returns[position] = value
  var tailSum = 0.0
  for i in 0 ..< tailCount: tailSum += returns[i]
  let scale = sqrt(horizon)
  let z = normalQuantile(confidence)
  let esMultiplier = exp(-0.5 * z * z) / sqrt(2.0 * PiValue) / (1.0 - confidence)
  var thirdMoment = 0.0
  var fourthMoment = 0.0
  for i in 0 ..< count:
    let difference = returns[i] - mean
    let square = difference * difference
    thirdMoment += square * difference
    fourthMoment += square * square
  thirdMoment /= float64(count)
  fourthMoment /= float64(count)
  let staged = [
    -returns[tailCount - 1] * portfolio * scale,
    -(tailSum / float64(tailCount)) * portfolio * scale,
    portfolio * (z * sampleSd - mean) * scale,
    portfolio * (esMultiplier * sampleSd - mean) * scale,
    mean,
    sampleSd,
    thirdMoment / (sampleSd * sampleSd * sampleSd),
    fourthMoment / (sampleSd * sampleSd * sampleSd * sampleSd) - 3.0,
  ]
  if output == nil or capacity < csize_t(staged.len): return -2
  for i in 0 ..< staged.len: output[i] = staged[i]
  int64(staged.len)
