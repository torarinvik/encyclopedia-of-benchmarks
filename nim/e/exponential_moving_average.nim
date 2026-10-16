proc putF64Le(output: ptr UncheckedArray[uint8], offset: int, value: float64) =
  let bits = cast[uint64](value)
  for byte in 0..<8: output[offset + byte] = uint8((bits shr (8 * byte)) and 0xFF'u64)

proc exponential_moving_average*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64 {.cdecl, exportc: "exponential_moving_average".} =
  if input.isNil or length < 3: return -1
  let window64 = input[0]
  let count64 = input[1]
  if window64 < 2 or window64 > 32 or count64 < 1 or count64 > 256: return -1
  let window = int(window64)
  let count = int(count64)
  if length != csize_t(count + 2): return -1
  for i in 0..<count:
    if input[2 + i] < -1_000_000'i64 or input[2 + i] > 1_000_000'i64: return -1
  if output.isNil or capacity < csize_t(count * 8): return -2
  let alpha = 2.0 / (1.0 + float64(window))
  var average = 0.0
  for i in 0..<count:
    let price = float64(input[2 + i])
    if i == 0: average = price
    elif i <= window: average = (average + price) * 0.5
    else: average = (alpha * price) + ((1.0 - alpha) * average)
    putF64Le(output, i * 8, average)
  int64(count * 8)
