const MaxN = 32
const MaxM = 32
const MaxInputValues = 2 + MaxN * MaxM + MaxN

proc storeU64Le(output: ptr UncheckedArray[uint8], offset: csize_t, value: uint64) =
  for byte in 0 ..< 8:
    output[offset + csize_t(byte)] = uint8((value shr (8 * byte)) and 255)

proc system_of_linear_equations_mod_2*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "system_of_linear_equations_mod_2".} =
  if input.isNil or length < 2 or length > csize_t(MaxInputValues): return -1
  let nValue = input[0]
  let mValue = input[1]
  if nValue < 1 or nValue > int64(MaxN) or mValue < 1 or mValue > int64(MaxM): return -1
  let n = int(nValue)
  let m = int(mValue)
  if length != csize_t(2 + n * m + n): return -1

  var rows: array[MaxN, uint64]
  var rhs: array[MaxN, uint8]
  for row in 0 ..< n:
    for column in 0 ..< m:
      let bit = input[2 + row * m + column]
      if bit != 0 and bit != 1: return -1
      rows[row] = rows[row] or (uint64(bit) shl column)
    let bit = input[2 + n * m + row]
    if bit != 0 and bit != 1: return -1
    rhs[row] = uint8(bit)

  var pivotColumns: array[MaxN, int]
  var pivotRow = 0
  for column in 0 ..< m:
    var pivot = pivotRow
    while pivot < n and ((rows[pivot] shr column) and 1) == 0: inc pivot
    if pivot == n: continue
    swap(rows[pivotRow], rows[pivot])
    swap(rhs[pivotRow], rhs[pivot])
    for row in 0 ..< n:
      if row != pivotRow and ((rows[row] shr column) and 1) != 0:
        rows[row] = rows[row] xor rows[pivotRow]
        rhs[row] = rhs[row] xor rhs[pivotRow]
    pivotColumns[pivotRow] = column
    inc pivotRow

  for row in pivotRow ..< n:
    if rows[row] == 0 and rhs[row] != 0:
      if output.isNil or capacity < 8: return -2
      storeU64Le(output, 0, high(uint64))
      return 8

  var isPivot: array[MaxM, bool]
  for row in 0 ..< pivotRow: isPivot[pivotColumns[row]] = true
  let nullity = m - pivotRow
  let outputBytes = 8 * (nullity + 2)
  if output.isNil or capacity < csize_t(outputBytes): return -2

  var particular = 0'u64
  for row in 0 ..< pivotRow:
    if rhs[row] != 0: particular = particular or (1'u64 shl pivotColumns[row])
  storeU64Le(output, 0, uint64(nullity))
  storeU64Le(output, 8, particular)
  var basisIndex = 0
  for freeColumn in 0 ..< m:
    if isPivot[freeColumn]: continue
    var basis = 1'u64 shl freeColumn
    for row in 0 ..< pivotRow:
      if ((rows[row] shr freeColumn) and 1) != 0:
        basis = basis or (1'u64 shl pivotColumns[row])
    storeU64Le(output, csize_t(16 + 8 * basisIndex), basis)
    inc basisIndex
  int64(outputBytes)
