import std/math

proc validUnit(unit: float64): bool =
  unit == 0.0 or unit == 1.0 or unit == 2.0 or unit == 3.0 or
  unit == 4.0 or unit == 5.0 or unit == 6.0 or unit == 7.0

proc toKelvin(value, unit: float64): float64 =
  if unit == 0.0: return value
  if unit == 1.0: return value + 273.15
  if unit == 2.0: return (value + 459.67) * 5.0 / 9.0
  if unit == 3.0: return value * 5.0 / 9.0
  if unit == 4.0: return 373.15 - value * 2.0 / 3.0
  if unit == 5.0: return value * 100.0 / 33.0 + 273.15
  if unit == 6.0: return value * 5.0 / 4.0 + 273.15
  (value - 7.5) * 40.0 / 21.0 + 273.15

proc fromKelvin(kelvin, unit: float64): float64 =
  if unit == 0.0: return kelvin
  if unit == 1.0: return kelvin - 273.15
  if unit == 2.0: return kelvin * 9.0 / 5.0 - 459.67
  if unit == 3.0: return kelvin * 9.0 / 5.0
  if unit == 4.0: return (373.15 - kelvin) * 3.0 / 2.0
  if unit == 5.0: return (kelvin - 273.15) * 33.0 / 100.0
  if unit == 6.0: return (kelvin - 273.15) * 4.0 / 5.0
  (kelvin - 273.15) * 21.0 / 40.0 + 7.5

proc temperature*(value, fromUnit, toUnit: float64): float64 {.cdecl, exportc: "temperature".} =
  if classify(value) == fcNan or classify(value) == fcInf or classify(value) == fcNegInf or
      value < -1_000_000.0 or value > 1_000_000.0 or
      not validUnit(fromUnit) or not validUnit(toUnit):
    return -1e300
  fromKelvin(toKelvin(value, fromUnit), toUnit)
