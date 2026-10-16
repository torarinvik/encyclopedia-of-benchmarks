import math

proc putF64Le(output: ptr UncheckedArray[uint8], offset: int, value: float64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8: output[offset + byte] = uint8((bits shr (8 * byte)) and 0xFF'u64)

proc dispersion*(values: ptr UncheckedArray[int64], length: csize_t,
                 output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "dispersion".} =
  if values == nil or length == 0 or length > 128: return -1
  for i in 0 ..< int(length):
    if values[i] < -10000 or values[i] > 10000: return -1
  if output == nil or capacity < 16: return -2
  var sum = 0.0
  for i in 0 ..< int(length): sum += float64(values[i])
  let mean = sum / float64(length)
  var squaredDeviations = 0.0
  for i in 0 ..< int(length):
    let deviation = float64(values[i]) - mean
    squaredDeviations += deviation * deviation
  let variance = squaredDeviations / float64(length)
  putF64Le(output, 0, variance)
  putF64Le(output, 8, sqrt(variance))
  16
