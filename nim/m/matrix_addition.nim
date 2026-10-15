proc storeI32Le(value: uint32, output: ptr UncheckedArray[uint8], offset: int) =
  for b in 0 ..< 4: output[offset + b] = uint8((value shr (8 * b)) and 255)

proc matrix_addition*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "matrix_addition".} =
  if input.isNil or length < 4: return -2
  if input[0] < 0 or input[0] > 16 or input[1] < 0 or input[1] > 16: return -2
  let rowsA = int(input[0]); let colsA = int(input[1])
  if rowsA == 0 and colsA != 0: return -2
  let cellsA = rowsA * colsA; let bdim = 2 + cellsA
  if bdim + 2 > int(length) or input[bdim] < 0 or input[bdim] > 16 or input[bdim + 1] < 0 or input[bdim + 1] > 16: return -2
  let rowsB = int(input[bdim]); let colsB = int(input[bdim + 1])
  if rowsB == 0 and colsB != 0: return -2
  let cellsB = rowsB * colsB
  if int(length) != bdim + 2 + cellsB: return -2
  if rowsA != rowsB or colsA != colsB: return -1
  for i in 0 ..< cellsA:
    if input[2 + i] < int64(low(int32)) or input[2 + i] > int64(high(int32)) or input[bdim + 2 + i] < int64(low(int32)) or input[bdim + 2 + i] > int64(high(int32)): return -2
  if cellsA == 0: return 0
  if output.isNil or outputCapacity < csize_t(cellsA * 4): return -3
  for i in 0 ..< cellsA:
    let sum = cast[uint32](cast[int32](input[2 + i])) + cast[uint32](cast[int32](input[bdim + 2 + i]))
    storeI32Le(sum, output, i * 4)
  int64(cellsA)
