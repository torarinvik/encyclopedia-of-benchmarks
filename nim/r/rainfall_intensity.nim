## Sherman rainfall intensity curve over bounded integer inputs.
import std/math

proc rainfall_intensity*(values: ptr UncheckedArray[int64], length: csize_t): float64
    {.cdecl, exportc: "rainfall_intensity".} =
  if values == nil or length != 6: return -1.0e300
  let k = values[0]
  let a = values[1]
  let b = values[2]
  let c = values[3]
  let period = values[4]
  let duration = values[5]
  if k < 1 or k > 1000 or a < 1 or a > 3 or b < 1 or b > 100 or c < 1 or c > 3 or period < 1 or period > 100 or duration < 1 or duration > 1000: return -1.0e300
  (float64(k) * pow(float64(period), float64(a))) / pow(float64(duration + b), float64(c))
