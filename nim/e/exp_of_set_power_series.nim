const
  Modulus = 998_244_353'i64
  MaxN = 5
  MaxSize = 32
  MaxInput = 33

proc subsetSize(mask: int): int =
  var x = mask
  while x != 0:
    result += x and 1
    x = x shr 1

proc storeLe(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  var bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8(bits and 255'u64)
    bits = bits shr 8

proc exp_of_set_power_series*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "exp_of_set_power_series".} =
  if input == nil or length < 2 or length > csize_t(MaxInput): return -1
  if input[0] < 0 or input[0] > MaxN: return -1
  let n = int(input[0])
  let size = 1 shl n
  if int(length) != 1 + size or input[1] != 0: return -1
  for mask in 0 ..< size:
    if input[1 + mask] < 0 or input[1 + mask] >= Modulus: return -1

  let bytes = 8 * size
  if output == nil or int(capacity) < bytes: return -2

  var inverse: array[MaxN + 1, int64]
  var values: array[MaxSize, int64]
  if n > 0: inverse[1] = 1
  if n >= 2:
    for k in 2 .. n:
      inverse[k] = Modulus - (Modulus div int64(k)) *
        inverse[int(Modulus mod int64(k))] mod Modulus
  values[0] = 1
  for mask in 1 ..< size:
    var total = 0'i64
    var subset = mask
    while subset != 0:
      var term = int64(subsetSize(subset)) * input[1 + subset] mod Modulus
      term = term * values[mask xor subset] mod Modulus
      total = (total + term) mod Modulus
      subset = (subset - 1) and mask
    values[mask] = total * inverse[subsetSize(mask)] mod Modulus
  for mask in 0 ..< size: storeLe(output, 8 * mask, values[mask])
  int64(bytes)
