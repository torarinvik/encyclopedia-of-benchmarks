import std/math

const MinValue = 1e-6
const MaxValue = 1e6

proc fast_inverse_sqrt_cpp*(value: float64): float64
    {.cdecl, exportc: "fast_inverse_sqrt_cpp".} =
  if classify(value) == fcNan or value < MinValue or value > MaxValue:
    return -1.0
  var y = value
  let x2 = y * 0.5
  var bits = cast[int64](y)
  bits = 0x5fe6eb50c7b537a9'i64 - (bits shr 1)
  y = cast[float64](bits)
  y = y * (1.5 - (x2 * y * y))
  y = y * (1.5 - (x2 * y * y))
  y
