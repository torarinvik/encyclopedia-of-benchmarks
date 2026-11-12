proc kahan_summation*(values: ptr UncheckedArray[float64], length: csize_t,
    output: ptr UncheckedArray[float64], capacity: csize_t): int64
    {.cdecl, exportc: "kahan_summation".} =
  if values == nil or length > 256: return -1
  for i in 0 ..< int(length):
    let value = values[i]
    if value != value or value < -1.0e100 or value > 1.0e100: return -1
  if output == nil or capacity < 1: return -2

  var sum = 0.0
  var correction = 0.0
  for i in 0 ..< int(length):
    let adjusted = values[i] - correction
    let next = sum + adjusted
    correction = (next - sum) - adjusted
    sum = next
  output[0] = sum
  1
