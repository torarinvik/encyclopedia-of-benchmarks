proc putI64Le(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0..<8: output[offset + byte] = uint8((bits shr (8 * byte)) and 0xFF'u64)

proc coordinate_compression*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "coordinate_compression".} =
  if input.isNil or length < 1: return -1
  let n64 = input[0]
  if n64 < 0 or n64 > 128 or length != csize_t(n64 + 1): return -1
  let n = int(n64)
  var sorted: array[128, int64]
  for i in 0..<n:
    let value = input[i + 1]
    if value < int64(low(int32)) or value > int64(high(int32)): return -1
    sorted[i] = value
  if capacity < csize_t(n * 8) or (n > 0 and output.isNil): return -2
  for i in 1..<n:
    let value = sorted[i]
    var j = i
    while j > 0 and sorted[j - 1] > value:
      sorted[j] = sorted[j - 1]
      dec j
    sorted[j] = value
  var ranks: array[128, int64]
  var rank = -1'i64
  for i in 0..<n:
    if i == 0 or sorted[i] != sorted[i - 1]: inc rank
    ranks[i] = rank
  for i in 0..<n:
    var low = 0
    var high = n
    while low < high:
      let middle = low + (high - low) div 2
      if sorted[middle] < input[i + 1]: low = middle + 1
      else: high = middle
    putI64Le(output, i * 8, ranks[low])
  int64(n * 8)
