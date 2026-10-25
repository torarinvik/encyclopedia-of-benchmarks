const MaxN = 64
const MaxInputLength = 1 + 4 * MaxN
const MaxValue = 2'i64

proc storeI64Le(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8((bits shr (8 * byte)) and 255'u64)

proc tsvc_s241_cross_coupled_product_map*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "tsvc_s241_cross_coupled_product_map".} =
  if input == nil or length < 9 or length > csize_t(MaxInputLength): return -1
  let nValue = input[0]
  if nValue < 2 or nValue > MaxN: return -1
  let n = int(nValue)
  if int(length) != 1 + 4 * n: return -1

  let aStart = 1
  let bStart = aStart + n
  let cStart = bStart + n
  let dStart = cStart + n
  var a, b: array[MaxN, int64]
  for i in 0 ..< n:
    a[i] = input[aStart + i]
    b[i] = input[bStart + i]
    if a[i] < -MaxValue or a[i] > MaxValue or
        b[i] < -MaxValue or b[i] > MaxValue or
        input[cStart + i] < -MaxValue or input[cStart + i] > MaxValue or
        input[dStart + i] < -MaxValue or input[dStart + i] > MaxValue: return -1
  if output == nil or outputCapacity < csize_t(16 * n): return -2

  for i in 0 ..< n - 1:
    let nextA = a[i + 1]
    a[i] = b[i] * input[cStart + i] * input[dStart + i]
    b[i] = a[i] * nextA * input[dStart + i]
  for i in 0 ..< n:
    storeI64Le(output, 8 * i, a[i])
    storeI64Le(output, 8 * (n + i), b[i])
  int64(2 * n)
