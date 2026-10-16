import math

const InvalidResult = -1.0e300

proc roundThreePython(value: float64): float64 =
  if value == 0.0: return value
  let negative = value < 0.0
  var normalized = if negative: -value else: value
  var exponent = 0
  while normalized >= 1.0:
    normalized *= 0.5
    inc exponent
  while normalized < 0.5:
    normalized *= 2.0
    dec exponent
  let significand = uint64(normalized * 9_007_199_254_740_992.0)
  let numerator = significand * 1000'u64
  let shift = 53 - exponent
  var milliunits = 0'u64
  if shift < 0:
    milliunits = numerator shl (-shift)
  elif shift == 0:
    milliunits = numerator
  elif shift < 64:
    let denominator = 1'u64 shl shift
    milliunits = numerator shr shift
    let remainder = numerator and (denominator - 1'u64)
    let half = denominator shr 1
    if remainder > half or (remainder == half and (milliunits and 1'u64) != 0'u64):
      inc milliunits
  let rounded = float64(milliunits) / 1000.0
  if negative: return -rounded
  return rounded

proc charging_capacitor*(values: ptr UncheckedArray[int64], length: csize_t): float64
    {.cdecl, exportc: "charging_capacitor".} =
  if values == nil or length != 4: return InvalidResult
  let voltageMicro = values[0]
  let resistanceMicro = values[1]
  let capacitanceMicro = values[2]
  let timeMicro = values[3]
  if voltageMicro < 1 or voltageMicro > 1_000_000_000_000'i64 or
      resistanceMicro < 1 or resistanceMicro > 1_000_000_000_000_000'i64 or
      capacitanceMicro < 1 or capacitanceMicro > 1_000_000_000_000'i64 or
      timeMicro < -1_000_000_000_000'i64 or timeMicro > 1_000_000_000_000'i64:
    return InvalidResult
  let sourceVoltage = float64(voltageMicro) / 1_000_000.0
  let resistance = float64(resistanceMicro) / 1_000_000.0
  let capacitance = float64(capacitanceMicro) / 1_000_000.0
  let timeSec = float64(timeMicro) / 1_000_000.0
  let exponent = -timeSec / (resistance * capacitance)
  if exponent > 10.0: return InvalidResult
  roundThreePython(sourceVoltage * (1.0 - exp(exponent)))
