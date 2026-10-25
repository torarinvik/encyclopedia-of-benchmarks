## Clean-room port of TSVC s128; see package README for provenance and rights.
const MaxN = 16
const MaxInputLength = 1 + 5 * MaxN

proc storeI64Le(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8((bits shr (byte * 8)) and 0xff'u64)

proc tsvc_s128_strided_coupled_update*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "tsvc_s128_strided_coupled_update".} =
  if input.isNil or length < 6 or length > csize_t(MaxInputLength): return -1
  if input[0] < 1 or input[0] > MaxN: return -1
  let n = int(input[0])
  let bCount = 2 * n
  if length != csize_t(1 + 5 * n): return -1
  var a: array[MaxN, int64]
  var b, c: array[2 * MaxN, int64]
  var d: array[MaxN, int64]
  for i in 0 ..< bCount:
    b[i] = input[1 + i]
    c[i] = input[1 + bCount + i]
    if b[i] < -100 or b[i] > 100 or c[i] < -100 or c[i] > 100: return -1
  for i in 0 ..< n:
    d[i] = input[1 + 2 * bCount + i]
    if d[i] < -100 or d[i] > 100: return -1
  let outputValues = 3 * n
  if output.isNil or capacity < csize_t(8 * outputValues): return -2
  var j = -1
  for i in 0 ..< n:
    let k = j + 1
    a[i] = b[k] - d[i]
    j = k + 1
    b[k] = a[i] + c[k]
  for i in 0 ..< n: storeI64Le(output, 8 * i, a[i])
  for i in 0 ..< bCount: storeI64Le(output, 8 * (n + i), b[i])
  int64(outputValues)
