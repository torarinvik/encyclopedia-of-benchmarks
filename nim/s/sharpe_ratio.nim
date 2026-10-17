import std/math

const MaxParseableLength = 67
const MaxSampleCount = 64'i64
const Scale = 1_000_000.0
const MinReturnMicro = -200_000'i64
const MaxReturnMicro = 200_000'i64
const MinRiskFreeMicro = -100_000'i64
const MaxRiskFreeMicro = 100_000'i64
const InvalidResult = -1.0e300

type I64Input = ptr UncheckedArray[int64]

proc sharpe_ratio*(values: I64Input, length: csize_t): float64
    {.cdecl, exportc: "sharpe_ratio".} =
  if values == nil or length < 2 or length > csize_t(MaxParseableLength): return InvalidResult
  let countValue = values[0]
  if countValue < 2 or countValue > MaxSampleCount or length != csize_t(countValue + 2):
    return InvalidResult
  let count = int(countValue)
  let riskFreeMicro = values[count + 1]
  if riskFreeMicro < MinRiskFreeMicro or riskFreeMicro > MaxRiskFreeMicro: return InvalidResult

  var sum = 0.0
  var constantReturns = true
  for index in 0 ..< count:
    let returnMicro = values[index + 1]
    if returnMicro < MinReturnMicro or returnMicro > MaxReturnMicro: return InvalidResult
    if returnMicro != values[1]: constantReturns = false
    sum += float64(returnMicro) / Scale
  if constantReturns: return InvalidResult

  let mean = sum / float64(count)
  let riskFreeRate = float64(riskFreeMicro) / Scale
  let excessReturn = mean - riskFreeRate
  var squaredDeviations = 0.0
  for index in 0 ..< count:
    let returnValue = float64(values[index + 1]) / Scale
    let difference = returnValue - mean
    squaredDeviations += pow(difference, 2.0)
  let variance = squaredDeviations / float64(count - 1)
  let standardDeviation = sqrt(variance)
  if standardDeviation == 0.0: return InvalidResult
  excessReturn / standardDeviation
