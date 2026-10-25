## Clean-room port of TSVC s453; see package README for provenance and rights.
const MaxN = 32
const MaxInputLength = 33

proc storeI64Le(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8((bits shr (byte * 8)) and 0xff'u64)

proc tsvc_s453_recurrence_weighted_scale*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "tsvc_s453_recurrence_weighted_scale".} =
  if input.isNil or length < 2 or length > csize_t(MaxInputLength): return -1
  if input[0] < 1 or input[0] > MaxN: return -1
  let n = int(input[0])
  if length != csize_t(1 + n): return -1
  var b, a: array[MaxN, int64]
  for i in 0 ..< n:
    b[i] = input[1 + i]
    if b[i] < -100 or b[i] > 100: return -1
  if output.isNil or capacity < csize_t(8 * n): return -2
  var s: int64 = 0
  for i in 0 ..< n:
    s += 2
    a[i] = s * b[i]
  for i in 0 ..< n: storeI64Le(output, 8 * i, a[i])
  int64(n)
