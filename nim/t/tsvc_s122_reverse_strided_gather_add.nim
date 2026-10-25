## Clean-room port of TSVC s122; see package README for provenance and rights.
const MaxN = 32
const MaxInputLength = 67

proc storeI64Le(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8((bits shr (byte * 8)) and 0xff'u64)

proc tsvc_s122_reverse_strided_gather_add*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "tsvc_s122_reverse_strided_gather_add".} =
  if input.isNil or length < 5 or length > csize_t(MaxInputLength): return -1
  if input[0] < 1 or input[0] > MaxN: return -1
  let n = int(input[0])
  if input[1] < 1 or input[1] > int64(n) or input[2] < 1 or input[2] > int64(n): return -1
  if length != csize_t(3 + 2 * n): return -1
  let start = int(input[1])
  let stride = int(input[2])
  var a, b: array[MaxN, int64]
  for i in 0 ..< n:
    a[i] = input[3 + i]
    b[i] = input[3 + n + i]
    if a[i] < -100 or a[i] > 100 or b[i] < -100 or b[i] > 100: return -1
  if output.isNil or capacity < csize_t(8 * n): return -2
  var j = 1
  var k = 0
  var i = start - 1
  while i < n:
    k += j
    a[i] += b[n - k]
    i += stride
  for i in 0 ..< n: storeI64Le(output, 8 * i, a[i])
  int64(n)
