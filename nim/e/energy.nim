## Pinned Rust energy conversion through joules, in source order.
const MaxValueMicro = 1_000_000_000_000'i64
const Scale = 1_000_000'i64
const MaxInputLength = 4
const InvalidResult = -1.0e300
const JoulesPerUnit: array[55, float64] = [
  1.0, 1000.0, 1000000.0, 1000000000.0, 0.001,
  1.0e-6, 1.0e-9, 1.0e-18, 1.0, 3600.0,
  1000.0, 3600000.0, 3600000000.0, 3600000000000.0, 1.0,
  1.0e-7, 1.0e-7, 4186.8, 4186800.0, 4.1868,
  4186.8, 4.184, 4184.0, 1.602176634e-19, 1.602176634e-16,
  1.602176634e-13, 1055.05585262, 1054.3499999744, 1055055852.62, 1.3558179483,
  1.3558179483, 0.112984829, 0.112984829, 0.0070615518, 0.0070615518,
  0.04214011, 2684519.5368856, 2647795.5, 9.8066499997, 0.0980665,
  9.8066499997, 0.00980665, 9.80665e-5, 105505600.0, 105505600.0,
  105480400.0, 12660670.23144, 40197627984.822, 6383087908.3509, 4184000000.0,
  4184000000000.0, 4.184e15, 4.184e18, 4.3597482e-18, 2.1798741e-18
]
proc energy*(values: ptr UncheckedArray[int64], length: csize_t): float64
    {.cdecl, exportc: "energy".} =
  if values == nil or length != 3 or length > csize_t(MaxInputLength): return InvalidResult
  let valueMicro=values[0]; let fromUnit=values[1]; let toUnit=values[2]
  if valueMicro < -MaxValueMicro or valueMicro > MaxValueMicro or fromUnit < 0 or fromUnit > 54 or toUnit < 0 or toUnit > 54: return InvalidResult
  let value = float64(valueMicro) / float64(Scale)
  let joules = value * JoulesPerUnit[int(fromUnit)]
  joules / JoulesPerUnit[int(toUnit)]
