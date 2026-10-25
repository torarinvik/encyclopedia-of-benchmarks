## Clean-room bounded port of TSVC s261; see package README for provenance.
const MaxN = 64
const MaxInputLength = 257

proc storeI64Le(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8((bits shr (8 * byte)) and 0xff'u64)

proc tsvc_s261_shifted_cross_array_update*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "tsvc_s261_shifted_cross_array_update".} =
  if input.isNil or length < 9 or length > csize_t(MaxInputLength): return -1
  if input[0] < 2 or input[0] > MaxN: return -1
  let n = int(input[0])
  if length != csize_t(1 + 4 * n): return -1
  var a, b, c, d: array[MaxN, int64]
  for i in 0 ..< n:
    a[i] = input[1 + i]
    b[i] = input[1 + n + i]
    c[i] = input[1 + 2 * n + i]
    d[i] = input[1 + 3 * n + i]
    if a[i] < -2 or a[i] > 2 or b[i] < -2 or b[i] > 2 or
        c[i] < -2 or c[i] > 2 or d[i] < -2 or d[i] > 2: return -1
  if output.isNil or capacity < csize_t(16 * n): return -2
  for i in 1 ..< n:
    let temporary = a[i] + b[i]
    a[i] = temporary + c[i - 1]
    let product = c[i] * d[i]
    c[i] = product
  for i in 0 ..< n:
    storeI64Le(output, 8 * i, a[i])
    storeI64Le(output, 8 * (n + i), c[i])
  int64(2 * n)
