const MaxAbsTemperatureMicro = 1_000_000_000_000'i64
const MaxInputLength = 3
const InvalidResult = -1.0e300

proc temperature_converter*(values: ptr UncheckedArray[int64], length: csize_t): float64
    {.cdecl, exportc: "temperature_converter".} =
  if values == nil or length != 2 or length > csize_t(MaxInputLength): return InvalidResult
  let operation = values[0]
  let temperatureMicro = values[1]
  if temperatureMicro < -MaxAbsTemperatureMicro or temperatureMicro > MaxAbsTemperatureMicro: return InvalidResult
  let temperature = float64(temperatureMicro) / 1_000_000.0
  case operation
  of 0: temperature * 9.0 / 5.0 + 32.0
  of 1: temperature + 273.15
  of 2: (temperature - 32.0) * 5.0 / 9.0
  of 3: (temperature - 32.0) * 5.0 / 9.0 + 273.15
  of 4: temperature - 273.15
  of 5: (temperature - 273.15) * 9.0 / 5.0 + 32.0
  else: InvalidResult
