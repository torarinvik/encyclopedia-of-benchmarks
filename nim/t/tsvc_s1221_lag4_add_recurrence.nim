## Clean-room port of TSVC s1221; see package README for provenance and rights.
const MinN = 5
const MaxN = 32
const MaxInputLength = 65

proc storeI64Le(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8((bits shr (byte * 8)) and 0xff'u64)

proc tsvc_s1221_lag4_add_recurrence*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "tsvc_s1221_lag4_add_recurrence".} =
  if input.isNil or length < 11 or length > csize_t(MaxInputLength): return -1
  if input[0] < MinN or input[0] > MaxN: return -1
  let n = int(input[0])
  if length != csize_t(1 + 2 * n): return -1
  var a, b: array[MaxN, int64]
  for i in 0 ..< n:
    a[i] = input[1 + i]
    b[i] = input[1 + n + i]
    if a[i] < -10 or a[i] > 10 or b[i] < -10 or b[i] > 10: return -1
  if output.isNil or capacity < csize_t(8 * n): return -2
  for i in 4 ..< n:
    b[i] = b[i - 4] + a[i]
  for i in 0 ..< n:
    storeI64Le(output, 8 * i, b[i])
  int64(n)
