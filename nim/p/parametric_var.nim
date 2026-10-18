import std/math

const MaxParseableInputLength = 69
const InvalidResult = -1'i64
const OutputError = -2'i64

proc finiteValue(value: float64): bool =
  let kind = classify(value)
  kind != fcNan and kind != fcInf and kind != fcNegInf

proc normalQuantile(probability: float64): float64 =
  let q = probability - 0.5
  if abs(q) <= 0.425:
    let r = 0.180625 - q * q
    var numerator = 2509.0809287301226727
    for coefficient in [33430.575583588128105, 67265.770927008700853,
        45921.953931549871457, 13731.693765509461125,
        1971.5909503065514427, 133.14166789178437745,
        3.387132872796366608]:
      numerator = numerator * r + coefficient
    var denominator = 5226.495278852854561
    for coefficient in [28729.085735721942674, 39307.89580009271061,
        21213.794301586595867, 5394.1960214247511077,
        687.1870074920579083, 42.313330701600911252, 1.0]:
      denominator = denominator * r + coefficient
    return q * numerator / denominator

  var r = sqrt(-ln(1.0 - probability)) - 1.6
  var numerator = 7.7454501427834140764e-4
  for coefficient in [0.0227238449892691845833, 0.24178072517745061177,
      1.27045825245236838258, 3.64784832476320460504,
      5.7694972214606914055, 4.6303378461565452959,
      1.42343711074968357734]:
    numerator = numerator * r + coefficient
  var denominator = 1.05075007164441684324e-9
  for coefficient in [5.475938084995344946e-4, 0.0151986665636164571966,
      0.14810397642748007459, 0.68976733498510000455,
      1.6763848301838038494, 2.05319162663775882187, 1.0]:
    denominator = denominator * r + coefficient
  result = numerator / denominator
  if q < 0.0: result = -result

proc calculateParametric(input: ptr UncheckedArray[float64], length: csize_t,
    output: ptr UncheckedArray[float64], outputCapacity: csize_t,
    expectedShortfall: bool): int64 =
  if input == nil or length < csize_t(4) or length > csize_t(MaxParseableInputLength):
    return InvalidResult
  for index in 0 ..< int(length):
    if not finiteValue(input[index]): return InvalidResult

  let portfolio = input[0]
  let confidence = input[1]
  let horizon = input[2]
  let rawCount = input[3]
  if portfolio < 100.0 or portfolio > 1_000_000.0 or
      confidence < 0.5 or confidence > 0.95 or
      horizon < 1.0 or horizon > 10.0 or
      floor(rawCount) != rawCount or rawCount < 20.0 or rawCount > 64.0:
    return InvalidResult
  let count = int(rawCount)
  if length != csize_t(4 + count): return InvalidResult

  var sum = 0.0
  for index in 0 ..< count:
    let value = input[4 + index]
    if value < -0.25 or value > 0.25: return InvalidResult
    sum += value
  let mean = sum / float64(count)
  var squaredDeviations = 0.0
  for index in 0 ..< count:
    let difference = input[4 + index] - mean
    squaredDeviations += difference * difference
  let sampleSd = sqrt(squaredDeviations / float64(count - 1))

  if output == nil or outputCapacity < 1: return OutputError
  let z = normalQuantile(confidence)
  let multiplier = if expectedShortfall:
    exp(-0.5 * z * z) / sqrt(2.0 * PI) / (1.0 - confidence)
  else:
    z
  output[0] = portfolio * (multiplier * sampleSd - mean) * sqrt(horizon)
  1

proc calculate_var_parametric*(input: ptr UncheckedArray[float64], length: csize_t,
    output: ptr UncheckedArray[float64], outputCapacity: csize_t): int64
    {.cdecl, exportc: "calculate_var_parametric".} =
  calculateParametric(input, length, output, outputCapacity, false)
