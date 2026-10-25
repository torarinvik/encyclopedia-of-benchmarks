## Clean-room port of TSVC s126; see package README for provenance and rights.
const MaxN = 6
const MaxCells = MaxN * MaxN
const MaxInputLength = 1 + 3 * MaxCells

proc storeI64Le(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8((bits shr (byte * 8)) and 0xff'u64)

proc tsvc_s126_matrix_column_recurrence*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "tsvc_s126_matrix_column_recurrence".} =
  if input.isNil or length < 13 or length > csize_t(MaxInputLength): return -1
  if input[0] < 2 or input[0] > MaxN: return -1
  let n = int(input[0])
  let cells = n * n
  if length != csize_t(1 + 3 * cells): return -1
  var coefficients, cMatrix, bMatrix: array[MaxCells, int64]
  for i in 0 ..< cells:
    coefficients[i] = input[1 + i]
    cMatrix[i] = input[1 + cells + i]
    bMatrix[i] = input[1 + 2 * cells + i]
    if coefficients[i] < -100 or coefficients[i] > 100 or
        cMatrix[i] < -100 or cMatrix[i] > 100 or bMatrix[i] < -100 or bMatrix[i] > 100: return -1
  let outputBytes = 8 * cells
  if output.isNil or capacity < csize_t(outputBytes): return -2
  var k = 1
  for i in 0 ..< n:
    for j in 1 ..< n:
      let target = j * n + i
      bMatrix[target] = bMatrix[target - n] + coefficients[k - 1] * cMatrix[target]
      inc k
    inc k
  for i in 0 ..< cells: storeI64Le(output, 8 * i, bMatrix[i])
  int64(cells)
