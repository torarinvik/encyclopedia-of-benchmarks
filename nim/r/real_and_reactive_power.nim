## Real/reactive power from apparent power and power factor.
import std/math

proc real_and_reactive_power*(values: ptr UncheckedArray[int64], length: csize_t): float64
    {.cdecl, exportc: "real_and_reactive_power".} =
  if length != 3 or values == nil: return -1.0e300
  let operation = values[0]
  let apparent_power = values[1]
  let factor_units = values[2]
  if (operation != 0 and operation != 1) or apparent_power < -1000000000 or apparent_power > 1000000000 or factor_units < -10000 or factor_units > 10000:
    return -1.0e300
  let power_factor = float64(factor_units) / 10000.0
  if operation == 0: return float64(apparent_power) * power_factor
  float64(apparent_power) * sqrt(1.0 - pow(power_factor, 2.0))
