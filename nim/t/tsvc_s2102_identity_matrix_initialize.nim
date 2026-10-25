# Clean-room bounded profile of TSVC s2102; see package README.
const MaxSide = 8
const MaxPasses = 8
const MaxCells = MaxSide * MaxSide

proc storeI64Le(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8((bits shr (8 * byte)) and 0xff'u64)

proc tsvc_s2102_identity_matrix_initialize*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "tsvc_s2102_identity_matrix_initialize".} =
  if input.isNil or length != 2: return -1
  let sideRaw = input[0]
  let passesRaw = input[1]
  if sideRaw < 1 or sideRaw > MaxSide or passesRaw < 1 or passesRaw > MaxPasses: return -1
  let side = int(sideRaw)
  let cells = side * side
  if output.isNil or outputCapacity < csize_t(8 * cells): return -2

  var matrix: array[MaxCells, int64]
  for _ in 0 ..< int(passesRaw):
    for col in 0 ..< side:
      for row in 0 ..< side: matrix[row * side + col] = 0
      matrix[col * side + col] = 1
  for cell in 0 ..< cells: storeI64Le(output, 8 * cell, matrix[cell])
  int64(cells)
