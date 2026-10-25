const MaxN = 64
const MaxInputLength = 1 + 5 * MaxN
const MaxValue = 2'i64

proc storeI64Le(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8((bits shr (8 * byte)) and 255'u64)

proc tsvc_s243_ordered_lookahead_update*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "tsvc_s243_ordered_lookahead_update".} =
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
    if a[i] < -MaxValue or a[i] > MaxValue or
        b[i] < -MaxValue or b[i] > MaxValue or
        input[cStart + i] < -MaxValue or input[cStart + i] > MaxValue or
        input[dStart + i] < -MaxValue or input[dStart + i] > MaxValue or
        input[eStart + i] < -MaxValue or input[eStart + i] > MaxValue: return -1
  if output == nil or outputCapacity < csize_t(16 * n): return -2

  for i in 0 ..< (n - 1):
    let nextA = a[i + 1]
    let dValue = input[dStart + i]
    a[i] = b[i] + input[cStart + i] * dValue
    b[i] = a[i] + dValue * input[eStart + i]
    a[i] = b[i] + nextA * dValue
  for i in 0 ..< n:
    storeI64Le(output, 8 * i, a[i])
    storeI64Le(output, 8 * (n + i), b[i])
  int64(2 * n)
