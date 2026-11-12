const MaxN = 8
const MaxSize = 1 shl MaxN
const MaxInputLength = 1 + 2 * MaxSize
const Modulus = 998_244_353'i64

proc xorWalshTransform(values: var array[MaxSize, int64], size: int) =
  var half = 1
  while half < size:
    var block = 0
    while block < size:
      for offset in 0..<half:
        let left = values[block + offset]
        let right = values[block + half + offset]
        values[block + offset] = (left + right) mod Modulus
        values[block + half + offset] = (left - right + Modulus) mod Modulus
      block += 2 * half
    half *= 2

proc storeI64Le(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0..<8:
    output[offset + byte] = uint8((bits shr (8 * byte)) and 255)

proc bitwise_xor_convolution*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "bitwise_xor_convolution".} =
  if input.isNil or length < 1 or length > csize_t(MaxInputLength): return -1
  let nValue = input[0]
  if nValue < 0 or nValue > MaxN: return -1
  let n = int(nValue)
  let size = 1 shl n
  if length != csize_t(1 + 2 * size): return -1
  for index in 0 ..< 2 * size:
    let value = input[1 + index]
    if value < 0 or value >= Modulus: return -1

  let outputBytes = 8 * size
  if output.isNil or capacity < csize_t(outputBytes): return -2
  var first, second: array[MaxSize, int64]
  for index in 0 ..< size:
    first[index] = input[1 + index]
    second[index] = input[1 + size + index]
  xorWalshTransform(first, size)
  xorWalshTransform(second, size)
  for index in 0 ..< size: first[index] = (first[index] * second[index]) mod Modulus
  xorWalshTransform(first, size)

  var inverseSize = 1'i64
  for _ in 0 ..< n: inverseSize = (inverseSize * ((Modulus + 1) div 2)) mod Modulus
  for index in 0 ..< size:
    storeI64Le(output, 8 * index, (first[index] * inverseSize) mod Modulus)
  int64(outputBytes)
