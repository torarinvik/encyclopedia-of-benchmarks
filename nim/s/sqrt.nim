import std/math

const MinValue = 1e-6
const MaxValue = 1e6

proc newtonStep(x2, y: float32): float32 =
  let product1 = x2 * y
  let product2 = product1 * y
  let correction = 1.5'f32 - product2
  y * correction

## Reciprocal of the pinned Go binary32 fast-inverse-square-root result.
proc go_sqrt_f32*(value: float64): float64 {.cdecl, exportc: "go_sqrt_f32".} =
  if classify(value) in {fcNan, fcInf, fcNegInf} or value < MinValue or value > MaxValue:
    return -1.0
  let number = float32(value)
  let x2 = number * 0.5'f32
  var bits = cast[uint32](number)
  bits = 0x5f3759df'u32 - (bits shr 1)
  var inverseRoot = cast[float32](bits)
  inverseRoot = newtonStep(x2, inverseRoot)
  inverseRoot = newtonStep(x2, inverseRoot)
  float64(1.0'f32 / inverseRoot)
