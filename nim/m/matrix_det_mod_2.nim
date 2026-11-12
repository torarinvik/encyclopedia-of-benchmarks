const MaxN = 64
const MaxInputValues = 1 + MaxN * MaxN

proc storeI64Le(output: ptr UncheckedArray[uint8], value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[byte] = uint8((bits shr (8 * byte)) and 255)

proc matrix_det_mod_2*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "matrix_det_mod_2".} =
  if input.isNil or length < 1 or length > csize_t(MaxInputValues): return -1
  let nValue = input[0]
  if nValue < 1 or nValue > int64(MaxN): return -1
  let n = int(nValue)
  if length != csize_t(1 + n * n): return -1

  var rows: array[MaxN, uint64]
  for row in 0 ..< n:
    for column in 0 ..< n:
      let bit = input[1 + row * n + column]
      if bit != 0 and bit != 1: return -1
      rows[row] = rows[row] or (uint64(bit) shl column)

  var pivotRow = 0
  for column in 0 ..< n:
    var pivot = pivotRow
    while pivot < n and ((rows[pivot] shr column) and 1) == 0: inc pivot
    if pivot == n: continue
    swap(rows[pivotRow], rows[pivot])
    for row in pivotRow + 1 ..< n:
      if ((rows[row] shr column) and 1) != 0: rows[row] = rows[row] xor rows[pivotRow]
    inc pivotRow

  if output.isNil or capacity < 8: return -2
  storeI64Le(output, if pivotRow == n: 1'i64 else: 0'i64)
  8
