import math

const SpeedOfLight = 299_792_458.0
const SpeedOfLightMilli = 299_792_458_000'i64
const MaxLengthTimeMilli = 1_000_000'i64
const MaxInputLength = 4
const InvalidResult = -1.0e300

proc lorentzGamma(velocity: float64): float64 =
  1.0 / sqrt(1.0 - velocity * velocity / (SpeedOfLight * SpeedOfLight))

proc relativity*(input: ptr UncheckedArray[int64], length: csize_t): float64
    {.cdecl, exportc: "relativity".} =
  if input.isNil or length < 3 or length > csize_t(MaxInputLength): return InvalidResult
  let operation = input[0]
  let arg1Milli = input[1]
  let arg2Milli = input[2]
  if length != 3: return InvalidResult

  if operation == 0:
    if arg2Milli != 0 or arg1Milli <= -SpeedOfLightMilli or arg1Milli >= SpeedOfLightMilli:
      return InvalidResult
    return lorentzGamma(float64(arg1Milli) / 1000.0)
  if operation == 1 or operation == 2:
    if arg1Milli < 0 or arg1Milli > MaxLengthTimeMilli or
        arg2Milli <= -SpeedOfLightMilli or arg2Milli >= SpeedOfLightMilli: return InvalidResult
    let quantity = float64(arg1Milli) / 1000.0
    let velocity = float64(arg2Milli) / 1000.0
    let gamma = lorentzGamma(velocity)
    if operation == 1: return quantity / gamma
    return quantity * gamma
  if operation == 3:
    if arg1Milli < -SpeedOfLightMilli or arg1Milli > SpeedOfLightMilli or
        arg2Milli <= -SpeedOfLightMilli or arg2Milli >= SpeedOfLightMilli: return InvalidResult
    let velocityOne = float64(arg1Milli) / 1000.0
    let frameVelocity = float64(arg2Milli) / 1000.0
    return (velocityOne - frameVelocity) /
      (1.0 - velocityOne * frameVelocity / (SpeedOfLight * SpeedOfLight))
  InvalidResult
