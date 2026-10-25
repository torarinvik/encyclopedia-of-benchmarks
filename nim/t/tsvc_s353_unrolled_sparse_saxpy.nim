## Clean-room port of TSVC s353; see package README for provenance and rights.
const MaxN = 20
const MaxInputLength = 2 + 3 * MaxN

proc storeI64Le(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8((bits shr (byte * 8)) and 0xff'u64)

proc tsvc_s353_unrolled_sparse_saxpy*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "tsvc_s353_unrolled_sparse_saxpy".} =
  if input.isNil or length < 17 or length > csize_t(MaxInputLength): return -1
  if input[0] < 5 or input[0] > MaxN or input[0] mod 5 != 0: return -1
  let n = int(input[0])
  if length != csize_t(2 + 3 * n): return -1
  let alpha = input[1]
  if alpha < -8 or alpha > 8: return -1
  var a, b, indices: array[MaxN, int64]
  for i in 0 ..< n:
    a[i] = input[2 + i]
    b[i] = input[2 + n + i]
    indices[i] = input[2 + 2 * n + i]
    if a[i] < -1_000_000 or a[i] > 1_000_000 or b[i] < -1_000_000 or b[i] > 1_000_000 or
        indices[i] < 0 or indices[i] >= int64(n): return -1
  let outputBytes = 8 * n
  if output.isNil or capacity < csize_t(outputBytes): return -2
  for i in countup(0, n - 5, 5):
    a[i] = a[i] + alpha * b[int(indices[i])]
    a[i + 1] = a[i + 1] + alpha * b[int(indices[i + 1])]
    a[i + 2] = a[i + 2] + alpha * b[int(indices[i + 2])]
    a[i + 3] = a[i + 3] + alpha * b[int(indices[i + 3])]
    a[i + 4] = a[i + 4] + alpha * b[int(indices[i + 4])]
  for i in 0 ..< n: storeI64Le(output, 8 * i, a[i])
  int64(n)
