## Clean-room port of TSVC s123; see package README for provenance and rights.
const MaxN = 32
const MaxInputLength = 129

proc storeI64Le(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8((bits shr (byte * 8)) and 0xff'u64)

proc tsvc_s123_conditional_pair_expansion*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "tsvc_s123_conditional_pair_expansion".} =
  if input.isNil or length < 5 or length > csize_t(MaxInputLength): return -1
  if input[0] < 1 or input[0] > MaxN: return -1
  let n = int(input[0])
  if length != csize_t(1 + 4 * n): return -1
  var b, c, d, e: array[MaxN, int64]
  var a: array[2 * MaxN, int64]
  for i in 0 ..< n:
    b[i] = input[1 + i]
    c[i] = input[1 + n + i]
    d[i] = input[1 + 2 * n + i]
    e[i] = input[1 + 3 * n + i]
    if b[i] < -100 or b[i] > 100 or c[i] < -100 or c[i] > 100 or
        d[i] < -100 or d[i] > 100 or e[i] < -100 or e[i] > 100: return -1
  if output.isNil or capacity < csize_t(16 * n): return -2
  var count = 0
  for i in 0 ..< n:
    let product = d[i] * e[i]
    a[count] = b[i] + product
    inc count
    if c[i] > 0:
      a[count] = c[i] + product
      inc count
  for i in 0 ..< count: storeI64Le(output, 8 * i, a[i])
  int64(count)
