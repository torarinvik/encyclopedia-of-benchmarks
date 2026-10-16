const MaxDimension = 32
const MaxInputLength = 2053

## Compare two bounded row-major integer matrices.
proc checkequal*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "checkequal".} =
  if values.isNil or length < 4 or length > csize_t(MaxInputLength): return -1

  let rowsA64 = values[0]
  let columnsA64 = values[1]
  let rowsB64 = values[2]
  let columnsB64 = values[3]
  if rowsA64 < 0 or rowsA64 > MaxDimension or columnsA64 < 0 or columnsA64 > MaxDimension
      or rowsB64 < 0 or rowsB64 > MaxDimension or columnsB64 < 0 or columnsB64 > MaxDimension:
    return -1

  let rowsA = int(rowsA64)
  let columnsA = int(columnsA64)
  let rowsB = int(rowsB64)
  let columnsB = int(columnsB64)
  let countA = rowsA * columnsA
  let countB = rowsB * columnsB
  if length != csize_t(4 + countA + countB): return -1
  if rowsA != rowsB or columnsA != columnsB: return 0
  for index in 0 ..< countA:
    if values[csize_t(4 + index)] != values[csize_t(4 + countA + index)]: return 0
  1
