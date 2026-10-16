import math
proc scaled_exponential_linear_unit*(values: ptr UncheckedArray[int64], length: csize_t, output: ptr UncheckedArray[uint8], capacity: csize_t): int64 {.cdecl, exportc: "scaled_exponential_linear_unit".} =
  if values == nil or length < 3 or length > 259: return -1
  let n = int(values[0])
  if n < 0 or n > 256 or int(length) != n+3 or values[1] < -10000000 or values[1] > 10000000 or values[2] < -10000000 or values[2] > 10000000: return -1
  for i in 0 ..< n: if values[i+3] < -20000000 or values[i+3] > 20000000: return -1
  let bytes = n*8
  if output == nil or int(capacity) < bytes: return -2
  let alpha = float64(values[1])/1e6; let lambda = float64(values[2])/1e6
  for i in 0 ..< n:
    let x = float64(values[i+3])/1e6
    let y = lambda * (if x > 0.0: x else: alpha*(exp(x)-1.0))
    let bits = cast[uint64](int64(floor(y*1e9+0.5)))
    for b in 0 ..< 8: output[i*8+b] = uint8((bits shr (8*b)) and 255)
  int64(bytes)
