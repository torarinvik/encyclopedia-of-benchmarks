import std/math

proc lowerBound(sorted: ptr UncheckedArray[float64], size: int, value: float64): int =
  var low = 0
  var high = size
  while low < high:
    let middle = low + (high - low) div 2
    if sorted[middle] < value: low = middle + 1 else: high = middle
  low

proc median_filter*(input: ptr UncheckedArray[float64], length: csize_t,
                    output: ptr UncheckedArray[float64], capacity: csize_t): int64
                    {.cdecl, exportc: "median_filter".} =
  if input == nil or length < 2 or length > 66: return -1
  let windowValue = input[0]
  let countValue = input[1]
  if classify(windowValue) in {fcNan, fcInf, fcNegInf} or floor(windowValue) != windowValue or windowValue < 1.0 or windowValue > 16.0 or
     classify(countValue) in {fcNan, fcInf, fcNegInf} or floor(countValue) != countValue or countValue < 0.0 or countValue > 64.0: return -1
  let window = int(windowValue)
  let count = int(countValue)
  if int(length) != 2 + count: return -1
  var samples: array[64, float64]
  for index in 0 ..< count:
    let value = input[2 + index]
    if classify(value) in {fcNan, fcInf, fcNegInf} or value < -1_000_000.0 or value > 1_000_000.0: return -1
    samples[index] = value
  if output == nil or capacity < csize_t(count): return -2

  var arrival: array[16, float64]
  var sorted: array[16, float64]
  var result: array[64, float64]
  var size = 0
  var oldest = 0
  for index in 0 ..< count:
    let value = samples[index]
    if size == window:
      let position = lowerBound(cast[ptr UncheckedArray[float64]](addr sorted[0]), size, arrival[oldest])
      for shift in position + 1 ..< size: sorted[shift - 1] = sorted[shift]
      dec size
    let position = lowerBound(cast[ptr UncheckedArray[float64]](addr sorted[0]), size, value)
    for shift in countdown(size - 1, position): sorted[shift + 1] = sorted[shift]
    sorted[position] = value
    arrival[oldest] = value
    oldest = (oldest + 1) mod window
    inc size
    let middle = size div 2
    result[index] = if size mod 2 != 0: sorted[middle] else: 0.5 * (sorted[middle - 1] + sorted[middle])
  for index in 0 ..< count: output[index] = result[index]
  int64(count)
