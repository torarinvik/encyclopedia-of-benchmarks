import std/math

const InvalidResult = -1.0e300
const PiValue = 3.14159265358979323846264338327950288
const EValue = 2.71828182845904523536028747135266250

proc gaussian_error_linear_unit_tanh*(x: float64): float64
    {.cdecl, exportc: "gaussian_error_linear_unit_tanh".} =
  if classify(x) == fcNan or x < -100.0 or x > 100.0: return InvalidResult
  let scale = pow(2.0 / PiValue, 0.5)
  let z = scale * (x + 0.044715 * pow(x, 3.0))
  let tanhValue = 2.0 / (1.0 + pow(EValue, -2.0 * z)) - 1.0
  x * 0.5 * (1.0 + tanhValue)
