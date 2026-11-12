const MaxN = 8
const MaxSize = 1 shl MaxN
const MaxInputLength = 1 + 2 * MaxSize
const Modulus = 998_244_353'i64

proc storeI64Le(output: ptr UncheckedArray[uint8], offset: csize_t, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + csize_t(byte)] = uint8((bits shr (8 * byte)) and 255)

proc bitwise_and_convolution*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "bitwise_and_convolution".} =
  if input.isNil or length < 1 or length > csize_t(MaxInputLength): return -1
  let nValue = input[0]
  if nValue < 0 or nValue > int64(MaxN): return -1
  let n = int(nValue)
  let size = 1 shl n
  if length != csize_t(1 + 2 * size): return -1
  for index in 0 ..< 2 * size:
    let value = input[1 + index]
    if value < 0 or value >= Modulus: return -1
  let outputBytes = 8 * size
  if output.isNil or capacity < csize_t(outputBytes): return -2

  var a: array[MaxSize, int64]
  var b: array[MaxSize, int64]
  for index in 0 ..< size:
    a[index] = input[1 + index]
    b[index] = input[1 + size + index]
  for bit in 0 ..< n:
    let bitMask = 1 shl bit
    for mask in 0 ..< size:
      if (mask and bitMask) == 0:
        a[mask] = (a[mask] + a[mask or bitMask]) mod Modulus
        b[mask] = (b[mask] + b[mask or bitMask]) mod Modulus
  for mask in 0 ..< size:
    a[mask] = (a[mask] * b[mask]) mod Modulus
  for bit in 0 ..< n:
    let bitMask = 1 shl bit
    for mask in 0 ..< size:
      if (mask and bitMask) == 0:
        a[mask] = a[mask] - a[mask or bitMask]
        if a[mask] < 0: a[mask] += Modulus
  for mask in 0 ..< size:
    storeI64Le(output, csize_t(8 * mask), a[mask])
  int64(outputBytes)
