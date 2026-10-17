const
  Scale = 1_000_000'i64
  MaxAbsTemperatureMicro = 1_000_000_000_000'i64
  MaxInputLength = 3
  InvalidResult = -1.0e300

proc temperature_conversions*(values: ptr UncheckedArray[int64], length: csize_t): float64
    {.cdecl, exportc: "temperature_conversions".} =
  if values.isNil or length != 2 or length > MaxInputLength.csize_t: return InvalidResult
  let operation = values[0]
  let micro = values[1]
  if micro < -MaxAbsTemperatureMicro or micro > MaxAbsTemperatureMicro: return InvalidResult
  case operation
  of 0:
    if micro mod 5_000_000 != 0: return InvalidResult
    float64(9 * (micro div 5_000_000) + 32)
  of 1:
    if (micro - 32_000_000) mod 9_000_000 != 0: return InvalidResult
    float64(5 * ((micro - 32_000_000) div 9_000_000))
  of 2:
    if micro mod Scale != 0: return InvalidResult
    float64(micro div Scale) + 273.15
  of 3:
    if (micro - 273_150_000) mod Scale != 0: return InvalidResult
    float64((micro - 273_150_000) div Scale)
  of 4:
    if (micro - 273_150_000) mod 5_000_000 != 0: return InvalidResult
    float64(9 * ((micro - 273_150_000) div 5_000_000) + 32)
  else: InvalidResult
