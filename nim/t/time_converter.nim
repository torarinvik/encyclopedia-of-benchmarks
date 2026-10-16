const Scale = 1_000_000'i64
const MaxTimeMicro = 1_000_000_000'i64
const MaxInputLength = 4
const InvalidResult = -1.0e300

proc secondsPerUnit(unit: int64): float64 =
  case unit
  of 0: 1.0
  of 1: 60.0
  of 2: 3600.0
  of 3: 86400.0
  of 4: 604800.0
  of 5: 2629800.0
  of 6: 31557600.0
  else: 0.0

proc time_converter*(values: ptr UncheckedArray[int64], length: csize_t): float64
    {.cdecl, exportc: "time_converter".} =
  if values == nil or length != 3 or length > csize_t(MaxInputLength): return InvalidResult
  let timeMicro = values[0]
  let fromUnit = values[1]
  let toUnit = values[2]
  if timeMicro < 0 or timeMicro > MaxTimeMicro or fromUnit < 0 or fromUnit > 6 or toUnit < 0 or toUnit > 6:
    return InvalidResult
  let timeValue = float64(timeMicro) / float64(Scale)
  let secondsValue = timeValue * secondsPerUnit(fromUnit)
  let converted = secondsValue / secondsPerUnit(toUnit)
  let rounded = int64(converted * 1000.0 + 0.5)
  float64(rounded) / 1000.0
