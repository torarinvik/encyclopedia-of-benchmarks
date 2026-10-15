import std/math

const MinValue = 1e-6
const MaxValue = 1e6

proc newtonStep(x2, y: float32): float32 =
  let product1 = x2 * y
  let product2 = product1 * y
  let correction = 1.5'f32 - product2
  y * correction

## Match Go's two binary32 Newton corrections after the magic-number seed.
proc fast_inverse_sqrt_go*(value: float64): float64
    {.cdecl, exportc: "fast_inverse_sqrt_go".} =
  if classify(value) in {fcNan, fcInf, fcNegInf} or value < MinValue or value > MaxValue:
    return -1.0
  let number = float32(value)
  let x2 = number * 0.5'f32
  var bits = cast[uint32](number)
  bits = 0x5f3759df'u32 - (bits shr 1)
  var y = cast[float32](bits)
  y = newtonStep(x2, y)
  y = newtonStep(x2, y)
  float64(y)
