const
  Modulus = 998_244_353'i64
  MaxN = 4
  MaxM = 8
  MaxSize = 16
  MaxInput = 35

proc storeLe(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  var bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8(bits and 255'u64)
    bits = bits shr 8

proc power_projection_of_set_power_series*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "power_projection_of_set_power_series".} =
  if input == nil or length < 2 or length > csize_t(MaxInput): return -1
  if input[0] < 0 or input[0] > MaxN or input[1] < 0 or input[1] > MaxM: return -1
  let n = int(input[0])
  let powers = int(input[1])
  let size = 1 shl n
  if int(length) != 2 + 2 * size: return -1

  var series: array[MaxSize, int64]
  var weights: array[MaxSize, int64]
  for mask in 0 ..< size:
    let a = input[2 + mask]
    let w = input[2 + size + mask]
    if a < 0 or a >= Modulus or w < 0 or w >= Modulus: return -1
    series[mask] = a
    weights[mask] = w

  let bytes = 8 * powers
  if output == nil or int(capacity) < bytes: return -2

  var current: array[MaxSize, int64]
  var next: array[MaxSize, int64]
  current[0] = 1
  for power in 0 ..< powers:
    var projection = 0'i64
    for mask in 0 ..< size:
      projection = (projection + weights[mask] * current[mask]) mod Modulus
    storeLe(output, 8 * power, projection)
    if power + 1 == powers: break
    for mask in 0 ..< size:
      var total = 0'i64
      var subset = mask
      while true:
        total = (total + current[subset] * series[mask xor subset]) mod Modulus
        if subset == 0: break
        subset = (subset - 1) and mask
      next[mask] = total
    for mask in 0 ..< size: current[mask] = next[mask]
  int64(bytes)
