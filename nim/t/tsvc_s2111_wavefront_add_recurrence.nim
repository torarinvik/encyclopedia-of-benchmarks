# Clean-room bounded profile of TSVC s2111; see package README.
const MaxSide = 8
const MaxPasses = 4
const MaxCells = MaxSide * MaxSide
const MaxInputLength = 2 + MaxCells

proc storeI64Le(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8((bits shr (8 * byte)) and 0xff'u64)

proc tsvc_s2111_wavefront_add_recurrence*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "tsvc_s2111_wavefront_add_recurrence".} =
  if input.isNil or length < 6 or length > csize_t(MaxInputLength): return -1
  let sideRaw = input[0]
  let passesRaw = input[1]
  if sideRaw < 2 or sideRaw > MaxSide or passesRaw < 1 or passesRaw > MaxPasses: return -1
  let side = int(sideRaw)
  let cells = side * side
  if length != csize_t(2 + cells): return -1

  var matrix: array[MaxCells, int64]
  for cell in 0 ..< cells:
    let value = input[2 + cell]
    if value < -8 or value > 8: return -1
    matrix[cell] = value
  if output.isNil or outputCapacity < csize_t(8 * cells): return -2

  for _ in 0 ..< int(passesRaw):
    for row in 1 ..< side:
      for col in 1 ..< side:
        matrix[row * side + col] = matrix[row * side + col - 1] + matrix[(row - 1) * side + col]
  for cell in 0 ..< cells: storeI64Le(output, 8 * cell, matrix[cell])
  int64(cells)
