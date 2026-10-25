## Clean-room bounded port of TSVC s252; see package README for provenance.
const MaxN = 64
const MaxInputLength = 129

proc storeI64Le(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8((bits shr (8 * byte)) and 0xff'u64)

proc tsvc_s252_adjacent_product_pair_sum*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "tsvc_s252_adjacent_product_pair_sum".} =
  if input.isNil or length < 3 or length > csize_t(MaxInputLength): return -1
  if input[0] < 1 or input[0] > MaxN: return -1
  let n = int(input[0])
  if length != csize_t(1 + 2 * n): return -1
  var b, c: array[MaxN, int64]
  for i in 0 ..< n:
    b[i] = input[1 + i]
    c[i] = input[1 + n + i]
    if b[i] < -2 or b[i] > 2 or c[i] < -2 or c[i] > 2: return -1
  if output.isNil or capacity < csize_t(8 * n): return -2
  var previousProduct = 0'i64
  for i in 0 ..< n:
    let product = b[i] * c[i]
    storeI64Le(output, 8 * i, product + previousProduct)
    previousProduct = product
  int64(n)
