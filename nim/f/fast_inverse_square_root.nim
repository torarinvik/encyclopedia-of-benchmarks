import std/math

const MinValue = 1e-6
const MaxValue = 1e6

## Match PHP's float32 pack/unpack through binary32 bit reinterpretation.
proc fast_inverse_square_root*(value: float64): float64
    {.cdecl, exportc: "fast_inverse_square_root".} =
  if classify(value) == fcNan or value < MinValue or value > MaxValue: return -1.0
  let seedInput = float32(value)
  var bits = cast[int32](seedInput)
  bits = 0x5f3759df'i32 - (bits shr 1)
  let seed = cast[float32](bits)
  let y = float64(seed)
  y * (1.5 - 0.5 * value * y * y)
