## Clean-room port of TSVC s114; see package README for provenance and rights.
const MaxN = 16
const MaxInputLength = 1 + 2 * MaxN * MaxN

proc storeI64Le(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8((bits shr (byte * 8)) and 0xff'u64)

proc tsvc_s114_transposed_lower_triangle_update*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "tsvc_s114_transposed_lower_triangle_update".} =
  if input.isNil or length < 9 or length > csize_t(MaxInputLength): return -1
  if input[0] < 2 or input[0] > MaxN: return -1
  let n = int(input[0])
  let cells = n * n
  if length != csize_t(1 + 2 * cells): return -1
  var a, b: array[MaxN * MaxN, int64]
  for i in 0 ..< cells:
    a[i] = input[1 + i]
    b[i] = input[1 + cells + i]
    if a[i] < -1_000_000 or a[i] > 1_000_000 or b[i] < -1_000_000 or b[i] > 1_000_000: return -1
  let outputBytes = 8 * cells
  if output.isNil or capacity < csize_t(outputBytes): return -2
  for i in 0 ..< n:
    for j in 0 ..< i:
      a[i * n + j] = a[j * n + i] + b[i * n + j]
  for i in 0 ..< cells: storeI64Le(output, 8 * i, a[i])
  int64(cells)
