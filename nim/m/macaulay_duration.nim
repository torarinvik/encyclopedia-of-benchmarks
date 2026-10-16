import std/math

const Scale = 1_000_000'i64
const MaxFaceValueMicro = 1_000_000_000_000'i64
const MaxRateMicro = 1_000_000'i64
const MaxPeriods = 64'i64
const MaxInputLength = 5
const InvalidResult = -1.0e300

proc macaulay_duration*(values: ptr UncheckedArray[int64], length: csize_t): float64
    {.cdecl, exportc: "macaulay_duration".} =
  if values == nil or length != 4 or length > csize_t(MaxInputLength): return InvalidResult
  let faceMicro = values[0]
  let couponMicro = values[1]
  let periods = values[2]
  let yieldMicro = values[3]
  if faceMicro < 1 or faceMicro > MaxFaceValueMicro or couponMicro < 0 or couponMicro > MaxRateMicro or periods < 1 or periods > MaxPeriods or yieldMicro < 1 or yieldMicro > MaxRateMicro: return InvalidResult
  let faceValue = float64(faceMicro) / float64(Scale)
  let couponRate = float64(couponMicro) / float64(Scale)
  let yieldRate = float64(yieldMicro) / float64(Scale)
  var totalPresentValue = 0.0
  var totalTimeWeightedValue = 0.0
  for period in 1..periods:
    let cashFlow = faceValue * couponRate + (if period == periods: faceValue else: 0.0)
    let timeWeightedValue = (float64(period) * cashFlow) / pow(1.0 + yieldRate, float64(period))
    totalTimeWeightedValue += timeWeightedValue
    let presentValue = cashFlow / pow(1.0 + yieldRate, float64(period))
    totalPresentValue += presentValue
  totalTimeWeightedValue / totalPresentValue
