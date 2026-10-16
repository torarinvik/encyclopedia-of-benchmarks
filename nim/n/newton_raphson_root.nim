import std/math

proc newton_raphson_root*(x0: float64): float64 {.cdecl, exportc: "newton_raphson_root".} =
  if classify(x0) in {fcNan, fcInf, fcNegInf} or x0 < 1.0 or x0 > 4.0:
    return -1e300
  var x = float32(x0)
  for _ in 0 ..< 1000:
    let square = x * x
    let residual = square - 3.0'f32
    if abs(residual) <= 1e-6'f32:
      return float64(x)
    let derivative = 2.0'f32 * x
    if derivative == 0.0'f32:
      return -1e300
    x = x - residual / derivative
  float64(x)
