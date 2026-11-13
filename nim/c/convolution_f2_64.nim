type
  InputWords = ptr UncheckedArray[int64]
  OutputBytes = ptr UncheckedArray[uint8]

const
  MaxN = 8
  MaxM = 8
  MaxParseable = 19

proc multiplyInField(leftValue, rightValue: uint64): uint64 =
  var shifted = leftValue
  var multiplier = rightValue
  var product = 0'u64
  for _ in 0 ..< 64:
    if (multiplier and 1'u64) != 0: product = product xor shifted
    let carry = shifted shr 63
    shifted = shifted shl 1
    if carry != 0: shifted = shifted xor 0x1b'u64
    multiplier = multiplier shr 1
  product

proc convolution_f2_64*(input: InputWords, length: csize_t,
                        output: OutputBytes, outputCapacity: csize_t): int64
    {.cdecl, exportc: "convolution_f2_64".} =
  if input == nil or length < csize_t(2) or length > csize_t(MaxParseable): return -1
  let n64 = input[0]
  let m64 = input[1]
  if n64 < 1 or n64 > MaxN or m64 < 1 or m64 > MaxM: return -1
  let n = int(n64)
  let m = int(m64)
  if length != csize_t(2 + n + m): return -1
  let count = n + m - 1
  let needed = csize_t(8 * count)
  if output == nil or outputCapacity < needed: return -2

  var a: array[MaxN, uint64]
  var b: array[MaxM, uint64]
  var product: array[MaxN + MaxM - 1, uint64]
  for i in 0 ..< n: a[i] = cast[uint64](input[2 + i])
  for j in 0 ..< m: b[j] = cast[uint64](input[2 + n + j])
  for i in 0 ..< n:
    for j in 0 ..< m:
      product[i + j] = product[i + j] xor multiplyInField(a[i], b[j])
  for i in 0 ..< count:
    for byte in 0 ..< 8:
      output[8 * i + byte] = uint8((product[i] shr (8 * byte)) and 255'u64)
  int64(needed)
