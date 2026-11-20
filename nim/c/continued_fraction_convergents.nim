const MaxInputLength = 18
type I64Array = ptr UncheckedArray[int64]
type ByteArray = ptr UncheckedArray[uint8]

proc storeI64Le(output: ByteArray, offset: int, value: int64) =
  var bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8(bits and 255)
    bits = bits shr 8

proc continued_fraction_convergents*(input: I64Array, length: csize_t,
    output: ByteArray, capacity: csize_t): int64
    {.cdecl, exportc: "continued_fraction_convergents".} =
  if input.isNil or length < 2 or length > csize_t(MaxInputLength): return -1
  let countValue = input[0]
  if countValue < 1 or countValue > 16 or input[1] < -1000 or input[1] > 1000: return -1
  let count = int(countValue)
  if length != csize_t(count + 1): return -1
  for index in 2 ..< int(length):
    if input[index] < 1 or input[index] > 8: return -1
  let required = 16 * count
  if output.isNil or capacity < csize_t(required): return -2

  var pTwoBack = 0'i64
  var pOneBack = 1'i64
  var qTwoBack = 1'i64
  var qOneBack = 0'i64
  for index in 0 ..< count:
    let p = input[index + 1] * pOneBack + pTwoBack
    let q = input[index + 1] * qOneBack + qTwoBack
    storeI64Le(output, 16 * index, p)
    storeI64Le(output, 16 * index + 8, q)
    pTwoBack = pOneBack; pOneBack = p
    qTwoBack = qOneBack; qOneBack = q
  int64(required)
