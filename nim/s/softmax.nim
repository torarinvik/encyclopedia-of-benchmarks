import std/math

proc softmax*(values: ptr UncheckedArray[float64], length: csize_t,
              output: ptr UncheckedArray[float64], capacity: csize_t): int64
    {.cdecl, exportc: "softmax".} =
  if values == nil or length < 1 or length > 64:
    return -1
  for index in 0 ..< int(length):
    if classify(values[index]) == fcNan or values[index] < -20.0 or values[index] > 20.0:
      return -1
  if output == nil or capacity < length:
    return -2

  var total = 0.0
  for index in 0 ..< int(length):
    total += exp(values[index])
  for index in 0 ..< int(length):
    output[index] = exp(values[index]) / total
  int64(length)
