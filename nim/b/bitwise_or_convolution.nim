const MaxN = 8
const MaxSize = 1 shl MaxN
const MaxInputLength = 1 + 2 * MaxSize
const Modulus = 998_244_353'i64

proc storeI64Le(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0..<8: output[offset + byte] = uint8((bits shr (8 * byte)) and 255)

proc bitwise_or_convolution*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "bitwise_or_convolution".} =
  if input.isNil or length < 1 or length > csize_t(MaxInputLength): return -1
  let nv = input[0]
  if nv < 0 or nv > MaxN: return -1
  let n = int(nv)
  let size = 1 shl n
  if length != csize_t(1 + 2 * size): return -1
  for i in 0 ..< 2 * size:
    let value = input[1 + i]
    if value < 0 or value >= Modulus: return -1
  let bytes = 8 * size
  if output.isNil or capacity < csize_t(bytes): return -2
  var a, b: array[MaxSize, int64]
  for i in 0 ..< size:
    a[i] = input[1 + i]
    b[i] = input[1 + size + i]
  for bit in 0 ..< n:
    let bitMask = 1 shl bit
    for mask in 0 ..< size:
      if (mask and bitMask) != 0:
        a[mask] = (a[mask] + a[mask xor bitMask]) mod Modulus
        b[mask] = (b[mask] + b[mask xor bitMask]) mod Modulus
  for i in 0 ..< size: a[i] = (a[i] * b[i]) mod Modulus
  for bit in 0 ..< n:
    let bitMask = 1 shl bit
    for mask in 0 ..< size:
      if (mask and bitMask) != 0:
        a[mask] -= a[mask xor bitMask]
        if a[mask] < 0: a[mask] += Modulus
  for i in 0 ..< size: storeI64Le(output, 8 * i, a[i])
  int64(bytes)
