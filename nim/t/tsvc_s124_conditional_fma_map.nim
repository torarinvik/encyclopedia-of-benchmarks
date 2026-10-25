## Clean-room port of TSVC s124; see package README for provenance and rights.
const MaxN = 32
const MaxInputLength = 1 + 4 * MaxN

proc storeI64Le(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8((bits shr (byte * 8)) and 0xff'u64)

proc tsvc_s124_conditional_fma_map*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "tsvc_s124_conditional_fma_map".} =
  if input.isNil or length < 5 or length > csize_t(MaxInputLength): return -1
  if input[0] < 1 or input[0] > MaxN: return -1
  let n = int(input[0])
  if length != csize_t(1 + 4 * n): return -1
  var a, b, c, d, e: array[MaxN, int64]
  for i in 0 ..< n:
    b[i] = input[1 + i]
    c[i] = input[1 + n + i]
    d[i] = input[1 + 2 * n + i]
    e[i] = input[1 + 3 * n + i]
    if b[i] < -100 or b[i] > 100 or c[i] < -100 or c[i] > 100 or
        d[i] < -100 or d[i] > 100 or e[i] < -100 or e[i] > 100: return -1
  if output.isNil or capacity < csize_t(8 * n): return -2
  var j = -1
  for i in 0 ..< n:
    if b[i] > 0:
      inc j
      a[j] = b[i] + d[i] * e[i]
    else:
      inc j
      a[j] = c[i] + d[i] * e[i]
  for i in 0 ..< n: storeI64Le(output, 8 * i, a[i])
  int64(n)
