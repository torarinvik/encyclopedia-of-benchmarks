import math

type I64Input = ptr UncheckedArray[int64]

func convertTemperature(operation: int64, value: float64): float64 =
  case operation
  of 0: (value * 9.0) / 5.0 + 32.0
  of 1: value + 273.15
  of 2: (value * 9.0) / 5.0 + 491.67
  of 3: ((value - 32.0) * 5.0) / 9.0
  of 4: ((value - 32.0) * 5.0) / 9.0 + 273.15
  of 5: value + 459.67
  of 6: value - 273.15
  of 7: ((value - 273.15) * 9.0) / 5.0 + 32.0
  of 8: (value * 9.0) / 5.0
  of 9: ((value - 491.67) * 5.0) / 9.0
  of 10: value - 459.67
  of 11: (value * 5.0) / 9.0
  of 12: value * 1.25
  of 13: value * 2.25 + 32.0
  of 14: value * 1.25 + 273.15
  else: value * 2.25 + 32.0 + 459.67

proc temperature_conversion*(values: I64Input, length: csize_t): int64 {.cdecl, exportc: "temperature_conversion".} =
  if values == nil or length != 2: return low(int64)
  let operation = values[0]
  let temperature = values[1]
  if operation < 0 or operation > 15 or temperature < -1000000 or temperature > 1000000: return low(int64)
  int64(floor(convertTemperature(operation, float64(temperature)) + 0.5))
