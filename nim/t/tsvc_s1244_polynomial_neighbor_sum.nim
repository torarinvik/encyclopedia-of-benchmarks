## Clean-room bounded port of TSVC s1244; see package README for provenance.
const MaxN = 32
const MaxInputLength = 129

proc storeI64Le(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8((bits shr (8 * byte)) and 0xff'u64)

proc tsvc_s1244_polynomial_neighbor_sum*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "tsvc_s1244_polynomial_neighbor_sum".} =
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
  for i in 0 ..< n - 1:
    let oldNextA = a[i + 1]
    a[i] = b[i] + c[i] * c[i] + b[i] * b[i] + c[i]
    d[i] = a[i] + oldNextA
  for i in 0 ..< n:
    storeI64Le(output, 8 * i, a[i])
    storeI64Le(output, 8 * (n + i), d[i])
  int64(2 * n)
