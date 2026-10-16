import math

const MaxSampleCount = 128

proc putF64Le(output: ptr UncheckedArray[uint8], offset: int, value: float64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8((bits shr (8 * byte)) and 0xFF'u64)

proc dataNormalizationStandardization*(values: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "data_normalization_standardization".} =
  if values == nil or length < 4 or length > csize_t(MaxSampleCount + 2): return -1
  let mode = values[0]
  let countArg = values[1]
  if (mode != 0 and mode != 1) or countArg < 2 or countArg > MaxSampleCount or
      length != csize_t(countArg + 2): return -1
  let count = int(countArg)
  var minimum = values[2]
  var maximum = values[2]
  var sum = 0.0
  for index in 0 ..< count:
    let value = values[index + 2]
    if value < -100000 or value > 100000: return -1
    if value < minimum: minimum = value
    if value > maximum: maximum = value
    sum += float64(value)
  if minimum == maximum: return -1
  let outputBytes = csize_t(count * 8)
  if output == nil or capacity < outputBytes: return -2
  if mode == 0:
    let span = float64(maximum - minimum)
    for index in 0 ..< count:
      let normalized = float64(values[index + 2] - minimum) / span
      putF64Le(output, index * 8, normalized)
  else:
    let mean = sum / float64(count)
    var squaredDeviations = 0.0
    for index in 0 ..< count:
      let deviation = float64(values[index + 2]) - mean
      squaredDeviations += deviation * deviation
    let sampleDeviation = sqrt(squaredDeviations / float64(count - 1))
    for index in 0 ..< count:
      let standardized = (float64(values[index + 2]) - mean) / sampleDeviation
      putF64Le(output, index * 8, standardized)
  int64(outputBytes)
