const InvalidResult = -1.0e300
const MaxSpeedMicro = 1_000_000_000_000_000'i64
const MaxRoundedMilli = 9_007_199_254_740_992.0
const ToKmh = [1.0, 3.6, 1.609344, 1.852, 1.09728, 1225.08, 1_079_252_848.8]
const FromKmh = [1.0, 0.277777778, 0.621371192, 0.539956803,
                 0.911344415, 0.000816164, 9.265669311e-10]

proc roundThreeAway(scaled: float64): float64 =
  if scaled == 0.0: return scaled / 1000.0
  let negative = scaled < 0.0
  let magnitude = if negative: -scaled else: scaled
  var roundedMilli = uint64(magnitude)
  if magnitude - float64(roundedMilli) >= 0.5: inc roundedMilli
  let rounded = float64(roundedMilli) / 1000.0
  if negative: return -rounded
  rounded

proc speed*(values: ptr UncheckedArray[int64], length: csize_t): float64
    {.cdecl, exportc: "speed".} =
  if values == nil or length != 3: return InvalidResult
  let speedMicro = values[0]
  let fromUnit = values[1]
  let toUnit = values[2]
  if speedMicro < -MaxSpeedMicro or speedMicro > MaxSpeedMicro or
      fromUnit < 0 or fromUnit > 6 or toUnit < 0 or toUnit > 6:
    return InvalidResult
  let speedValue = float64(speedMicro) / 1_000_000.0
  let kmh = speedValue * ToKmh[int(fromUnit)]
  let converted = kmh * FromKmh[int(toUnit)]
  let scaled = converted * 1000.0
  if scaled > MaxRoundedMilli or scaled < -MaxRoundedMilli: return InvalidResult
  roundThreeAway(scaled)
