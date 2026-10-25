## Clean-room port of TSVC s125; see package README for provenance and rights.
const MaxN = 8
const MaxCells = MaxN * MaxN
const MaxInputLength = 1 + 3 * MaxCells

proc storeI64Le(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8((bits shr (byte * 8)) and 0xff'u64)

proc tsvc_s125_matrix_flattened_fma*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "tsvc_s125_matrix_flattened_fma".} =
  if input.isNil or length < 4 or length > csize_t(MaxInputLength): return -1
  if input[0] < 1 or input[0] > MaxN: return -1
  let n = int(input[0])
  let cells = n * n
  if length != csize_t(1 + 3 * cells): return -1
  var aa, bb, cc, flatOutput: array[MaxCells, int64]
  for i in 0 ..< cells:
    aa[i] = input[1 + i]
    bb[i] = input[1 + cells + i]
    cc[i] = input[1 + 2 * cells + i]
    if aa[i] < -100 or aa[i] > 100 or bb[i] < -100 or bb[i] > 100 or cc[i] < -100 or cc[i] > 100: return -1
  let outputBytes = 8 * cells
  if output.isNil or capacity < csize_t(outputBytes): return -2
  var k = 0
  for i in 0 ..< n:
    for j in 0 ..< n:
      flatOutput[k] = aa[k] + bb[k] * cc[k]
      inc k
  for i in 0 ..< cells: storeI64Le(output, 8 * i, flatOutput[i])
  int64(cells)
