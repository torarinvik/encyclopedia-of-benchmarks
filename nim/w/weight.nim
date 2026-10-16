## Convert the pinned Rust weight units through kilograms, in source order.
const WeightFactors: array[23, float64] = [
  1e12, 1e9, 1000.0, 1.0, 1e-3, 1e-6, 1e-9, 1e-12, 1e-15,
  1016.0469088, 907.18474, 50.80234544, 12.70058636,
  6.35029318, 0.45359237, 0.028349523125, 0.0017718451953125, 0.00006479891,
  0.3732417216, 0.0311034768, 0.00155517384, 0.0002, 1.66053906660e-27
]

proc weightFactor(code: float64): float64 =
  if code != code or code < 0.0 or code > 22.0: return 0.0
  let index = int(code)
  if float64(index) != code: return 0.0
  WeightFactors[index]

proc weight*(value, fromCode, toCode: float64): float64
    {.cdecl, exportc: "weight".} =
  if value != value or value < -1_000_000.0 or value > 1_000_000.0: return -1e300
  let fromFactor = weightFactor(fromCode)
  let toFactor = weightFactor(toCode)
  if fromFactor == 0.0 or toFactor == 0.0: return -1e300
  let kilograms = value * fromFactor
  kilograms / toFactor
