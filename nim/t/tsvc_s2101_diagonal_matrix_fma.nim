const MaxN = 8
const MaxCells = MaxN * MaxN
const MaxInputLength = 1 + 3 * MaxCells
const MaxValue = 100'i64

proc storeI64Le(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8((bits shr (8 * byte)) and 255'u64)

proc tsvc_s2101_diagonal_matrix_fma*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "tsvc_s2101_diagonal_matrix_fma".} =
  if input == nil or length < 4 or length > csize_t(MaxInputLength): return -1
  let nValue = input[0]
  if nValue < 1 or nValue > MaxN: return -1
  let n = int(nValue)
  let cells = n * n
  if int(length) != 1 + 3 * cells: return -1
  for i in 0 ..< 3 * cells:
    if input[i + 1] < -MaxValue or input[i + 1] > MaxValue: return -1
  if output == nil or outputCapacity < csize_t(8 * cells): return -2

  for cell in 0 ..< cells:
    storeI64Le(output, 8 * cell, input[cell + 1])
  for i in 0 ..< n:
    let diagonal = i * n + i
    let value = input[1 + diagonal] + input[1 + cells + diagonal] * input[1 + 2 * cells + diagonal]
    storeI64Le(output, 8 * diagonal, value)
  int64(cells)
