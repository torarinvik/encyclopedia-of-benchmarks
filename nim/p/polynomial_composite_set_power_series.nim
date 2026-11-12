const
  Modulus = 998_244_353'i64
  MaxCoefficients = 8
  MaxN = 4
  MaxSize = 16
  MaxInput = 27

proc storeLe(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  var bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8(bits and 255'u64)
    bits = bits shr 8

proc polynomial_composite_set_power_series*(input: ptr UncheckedArray[int64],
    length: csize_t, output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "polynomial_composite_set_power_series".} =
  if input == nil or length < 2 or length > csize_t(MaxInput): return -1
  if input[0] < 0 or input[0] > MaxCoefficients or input[1] < 0 or input[1] > MaxN:
    return -1
  let count = int(input[0])
  let n = int(input[1])
  let size = 1 shl n
  if int(length) != 2 + count + size: return -1
  for index in 0 ..< count + size:
    if input[2 + index] < 0 or input[2 + index] >= Modulus: return -1

  let bytes = 8 * size
  if output == nil or capacity < csize_t(bytes): return -2

  var series: array[MaxSize, int64]
  var result: array[MaxSize, int64]
  var temporary: array[MaxSize, int64]
  for mask in 0 ..< size:
    series[mask] = input[2 + count + mask]

  var degree = count
  while degree > 0:
    for mask in 0 ..< size:
      var total = 0'i64
      var subset = mask
      while true:
        total = (total + result[subset] * series[mask xor subset]) mod Modulus
        if subset == 0: break
        subset = (subset - 1) and mask
      temporary[mask] = total
    temporary[0] = (temporary[0] + input[1 + degree]) mod Modulus
    for mask in 0 ..< size:
      result[mask] = temporary[mask]
    dec degree

  for mask in 0 ..< size: storeLe(output, 8 * mask, result[mask])
  int64(bytes)
