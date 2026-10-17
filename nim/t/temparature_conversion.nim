import std/math

const MaxAbsTemperatureMicro = 1_000_000_000_000'i64
const MaxInputLength = 4
const InvalidResult = -1.0e300

proc roundNearestTiesEven(value: float64): float64 =
  let lower = floor(value)
  let fraction = value - lower
  if fraction < 0.5: return lower
  if fraction > 0.5: return lower + 1.0
  let integer = int64(lower)
  if integer mod 2 == 0: lower else: lower + 1.0

proc roundDigits(value: float64, digits: int64): float64 =
  var scale = 1.0
  let magnitude = if digits < 0: -digits else: digits
  for _ in 0 ..< int(magnitude): scale *= 10.0
  let scaled = if digits >= 0: value * scale else: value / scale
  let rounded = roundNearestTiesEven(scaled)
  if digits >= 0: rounded / scale else: rounded * scale

proc temparature_conversion*(input: ptr UncheckedArray[int64], length: csize_t): float64
    {.cdecl, exportc: "temparature_conversion".} =
  if input == nil or length < 3 or length > csize_t(MaxInputLength): return InvalidResult
  let operation = input[0]
  let temperatureMicro = input[1]
  let digits = input[2]
  if length != 3 or operation < 0 or operation > 5
      or temperatureMicro < -MaxAbsTemperatureMicro or temperatureMicro > MaxAbsTemperatureMicro
      or digits < -6 or digits > 6: return InvalidResult

  let temperature = float64(temperatureMicro) / 1_000_000.0
  var resultValue: float64
  case operation
  of 0: resultValue = temperature * 1.8 + 32.0
  of 1: resultValue = temperature + 273.15
  of 2: resultValue = (temperature - 32.0) * 5.0 / 9.0
  of 3: resultValue = (temperature - 32.0) * 5.0 / 9.0 + 273.15
  of 4: resultValue = temperature - 273.15
  else: resultValue = (temperature - 273.15) * 1.8 + 32.0
  roundDigits(resultValue, digits)
