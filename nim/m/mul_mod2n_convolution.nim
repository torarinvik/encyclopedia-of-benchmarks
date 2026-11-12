const MaxN = 5
const MaxP = 32
const MaxInput = 66
const MaxOutput = 256
const Mod = 998_244_353'i64

proc storeLe(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8: output[offset + byte] = uint8((bits shr (8 * byte)) and 255'u64)

proc mul_mod2n_convolution*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "mul_mod2n_convolution".} =
  if input == nil or length < 3 or length > csize_t(MaxInput): return -1
  let n0 = input[0]
  if n0 < 0 or n0 > MaxN: return -1
  let p = 1 shl int(n0)
  if int(length) != 1 + 2 * p: return -1
  for i in 1 ..< int(length):
    if input[i] < 0 or input[i] >= Mod: return -1
  let bytes = 8 * p
  if bytes > MaxOutput: return -1
  if output == nil or int(capacity) < bytes: return -2
  var a, b, result: array[MaxP, int64]
  for i in 0 ..< p: a[i] = input[1 + i]; b[i] = input[1 + p + i]
  let mask = p - 1
  for i in 0 ..< p:
    for j in 0 ..< p:
      let k = (i * j) and mask
      result[k] = (result[k] + a[i] * b[j]) mod Mod
  for i in 0 ..< p: storeLe(output, 8 * i, result[i])
  int64(bytes)
