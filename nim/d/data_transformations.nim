import math

const MaxSampleCount = 128

proc roundThreeDecimals(value: float64): float64 =
  let bits = cast[uint64](value)
  let negative = (bits shr 63) != 0
  let exponent = int((bits shr 52) and 0x7FF'u64)
  let fraction = bits and ((1'u64 shl 52) - 1)
  let significand = if exponent == 0: fraction else: fraction or (1'u64 shl 52)
  let exponent2 = if exponent == 0: -1074 else: exponent - 1023 - 52
  let scaled = significand * 1000'u64
  var rounded = 0'u64
  if exponent2 >= 0:
    rounded = scaled shl exponent2
  else:
    let shift = -exponent2
    if shift < 64:
      rounded = scaled shr shift
      if shift > 0:
        let remainder = scaled and ((1'u64 shl shift) - 1)
        let half = 1'u64 shl (shift - 1)
        if remainder > half or (remainder == half and (rounded and 1'u64) != 0):
          inc rounded
  let roundedValue = float64(rounded) / 1000.0
  if negative: -roundedValue else: roundedValue

proc putF64Le(output: ptr UncheckedArray[uint8], offset: int, value: float64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8((bits shr (8 * byte)) and 0xFF'u64)

proc dataTransformations*(values: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "data_transformations".} =
  if values == nil or length < 4 or length > csize_t(MaxSampleCount + 2): return -1
  let mode = values[0]
  let countArg = values[1]
  if (mode != 0 and mode != 1) or countArg < 2 or countArg > MaxSampleCount or
      length != csize_t(countArg + 2): return -1
  let count = int(countArg)
  var minimum = values[2]
  var maximum = values[2]
  var sum = 0'i64
  var sumSquares = 0'i64
  for index in 0 ..< count:
    let value = values[index + 2]
    if value < -100000 or value > 100000: return -1
    if value < minimum: minimum = value
    if value > maximum: maximum = value
    sum += value
    sumSquares += value * value
  if minimum == maximum: return -1
  let outputBytes = csize_t(count * 8)
  if output == nil or capacity < outputBytes: return -2
  if mode == 0:
    let span = float64(maximum - minimum)
    for index in 0 ..< count:
      let normalized = float64(values[index + 2] - minimum) / span
      putF64Le(output, index * 8, roundThreeDecimals(normalized))
  else:
    let average = float64(sum) / float64(count)
    let varianceNumerator = int64(count) * sumSquares - sum * sum
    let varianceDenominator = float64(count * (count - 1))
    let deviation = sqrt(float64(varianceNumerator) / varianceDenominator)
    for index in 0 ..< count:
      let standardized = (float64(values[index + 2]) - average) / deviation
      putF64Le(output, index * 8, roundThreeDecimals(standardized))
  int64(outputBytes)
