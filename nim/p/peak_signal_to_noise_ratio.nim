## Peak signal-to-noise ratio for two non-identical 8-bit pixel arrays.
import math

proc peak_signal_to_noise_ratio*(v: ptr int64, n: uint64): float64 {.cdecl, exportc: "peak_signal_to_noise_ratio".} =
  if v == nil or n < 3 or n > 129 or v[0] < 1 or v[0] > 64 or n != 1'u64 + 2'u64 * uint64(v[0]): return -1e300
  let count = uint64(v[0])
  var sum = 0.0
  for i in 0'u64 ..< count:
    let a = v[i + 1]
    let b = v[i + 1 + count]
    if a < 0 or a > 255 or b < 0 or b > 255: return -1e300
    if a - b < -15 or a - b > 15: return -1e300
    let d = float64(a) - float64(b)
    sum += d * d
  let mse = sum / float64(count)
  if mse == 0.0: return -1e300
  20.0 * log10(255.0 / sqrt(mse))
