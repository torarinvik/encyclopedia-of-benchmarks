proc factor(code: float64): float64 =
  if code == 0.0: return 1.0
  if code == 1.0: return 1000.0
  if code == 2.0: return 1000000.0
  if code == 3.0: return 1000000000.0
  if code == 4.0: return 1.0
  if code == 5.0: return 3600.0
  if code == 6.0: return 3600000.0
  if code == 7.0: return 1.0
  if code == 8.0: return 4186.8
  if code == 9.0: return 4186800.0
  if code == 10.0: return 1.602176634e-19
  if code == 11.0: return 1055.05585
  if code == 12.0: return 1.355818
  0.0

proc energy_conversions*(value, fromCode, toCode: float64): float64
    {.cdecl, exportc: "energy_conversions".} =
  if value != value or value < -1_000_000.0 or value > 1_000_000.0:
    return -1e300
  let source = factor(fromCode)
  let target = factor(toCode)
  if source == 0.0 or target == 0.0: return -1e300
  let scaled = value * source
  scaled / target
