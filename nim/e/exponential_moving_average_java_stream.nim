proc putF64Le(output: ptr UncheckedArray[uint8], offset: int, value: float64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8: output[offset + byte] = uint8((bits shr (8 * byte)) and 255)

proc putI64Le(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8: output[offset + byte] = uint8((bits shr (8 * byte)) and 255)

proc exponential_moving_average_java_stream*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64 {.cdecl, exportc: "exponential_moving_average_java_stream".} =
  if input.isNil or length < 2 or input[1] < 0 or input[1] > 256 or int(length) != 2 + int(input[1]): return -1
  if input[0] < -1_000_000 or input[0] > 1_000_000: return -1
  var mean = float64(input[0]); var variance = 0.0
  for index in 0 ..< int(input[1]):
    let sample = input[index + 2]
    if sample < -1_000_000 or sample > 1_000_000: return -1
    let deviation = float64(sample) - mean
    mean += 0.25 * deviation
    variance = 0.75 * (variance + 0.25 * deviation * deviation)
  if output.isNil or capacity < 24: return -2
  putF64Le(output, 0, mean); putF64Le(output, 8, variance); putI64Le(output, 16, input[1])
  24
