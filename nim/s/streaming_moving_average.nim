proc putF64Le(output: ptr UncheckedArray[uint8], offset: int, value: float64) =
  let bits = cast[uint64](value)
  for byte in 0..<8: output[offset + byte] = uint8((bits shr (8 * byte)) and 0xFF'u64)

proc streaming_moving_average*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64 {.cdecl, exportc: "streaming_moving_average".} =
  if input.isNil or length < 3: return -1
  let window64 = input[0]
  let count64 = input[1]
  if window64 < 1 or window64 > 256 or count64 < 1 or count64 > 256: return -1
  let window = int(window64)
  let count = int(count64)
  if length != csize_t(count + 2): return -1
  for i in 0..<count:
    if input[2 + i] < -2_147_483_648'i64 or input[2 + i] > 2_147_483_647'i64: return -1
  if capacity < csize_t(count * 8) or output.isNil: return -2
  for i in 0..<count:
    let start = if i + 1 > window: i + 1 - window else: 0
    var sum = 0'i64
    for j in start..i: sum += input[2 + j]
    putF64Le(output, i * 8, float64(sum) / float64(i + 1 - start))
  int64(count * 8)
