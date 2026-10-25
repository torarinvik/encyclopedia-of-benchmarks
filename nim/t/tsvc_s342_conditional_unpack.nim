const MaxN = 64
const MaxInputLength = 1 + 2 * MaxN
const MaxValue = 2'i64

proc storeI64Le(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8((bits shr (8 * byte)) and 255'u64)

proc tsvc_s342_conditional_unpack*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "tsvc_s342_conditional_unpack".} =
  if input == nil or length < 3 or length > csize_t(MaxInputLength): return -1
  let nValue = input[0]
  if nValue < 1 or nValue > MaxN: return -1
  let n = int(nValue)
  if int(length) != 1 + 2 * n: return -1

  let aStart = 1
  let bStart = aStart + n
  var a: array[MaxN, int64]
  for i in 0 ..< n:
    a[i] = input[aStart + i]
    if a[i] < -MaxValue or a[i] > MaxValue or
        input[bStart + i] < -MaxValue or input[bStart + i] > MaxValue: return -1
  if output == nil or outputCapacity < csize_t(8 * n): return -2

  var packedIndex = 0
  for i in 0 ..< n:
    if a[i] > 0:
      a[i] = input[bStart + packedIndex]
      inc packedIndex
  for i in 0 ..< n:
    storeI64Le(output, 8 * i, a[i])
  int64(n)
