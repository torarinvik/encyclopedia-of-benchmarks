const MaxN = 64
const MaxInputLength = 1 + 5 * MaxN

proc boundedValue(value: int64): bool = value >= -1 and value <= 1

proc storeI64Le(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8((bits shr (8 * byte)) and 255'u64)

proc tsvc_s323_coupled_recurrence*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "tsvc_s323_coupled_recurrence".} =
  if input == nil or length < 11 or length > csize_t(MaxInputLength): return -1
  let nValue = input[0]
  if nValue < 2 or nValue > MaxN: return -1
  let n = int(nValue)
  if int(length) != 1 + 5 * n: return -1

  let aStart = 1
  let bStart = aStart + n
  let cStart = bStart + n
  let dStart = cStart + n
  let eStart = dStart + n
  var a, b: array[MaxN, int64]
  for i in 0 ..< n:
    a[i] = input[aStart + i]
    b[i] = input[bStart + i]
    if not boundedValue(a[i]) or not boundedValue(b[i]) or
        not boundedValue(input[cStart + i]) or not boundedValue(input[dStart + i]) or
        not boundedValue(input[eStart + i]): return -1
  if output == nil or outputCapacity < csize_t(16 * n): return -2

  for i in 1 ..< n:
    a[i] = b[i - 1] + input[cStart + i] * input[dStart + i]
    b[i] = a[i] + input[cStart + i] * input[eStart + i]
  for i in 0 ..< n:
    storeI64Le(output, 8 * i, a[i])
    storeI64Le(output, 8 * (n + i), b[i])
  int64(2 * n)
