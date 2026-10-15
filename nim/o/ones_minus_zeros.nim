const MaxCells = 100000
const MaxDimension = 100000

proc readCount(output: ptr UncheckedArray[uint8], cell: int): int64 =
  let position = 4 * cell
  let encoded = uint32(output[position]) or (uint32(output[position + 1]) shl 8) or
      (uint32(output[position + 2]) shl 16) or (uint32(output[position + 3]) shl 24)
  int64(encoded)

proc writeI32(output: ptr UncheckedArray[uint8], cell: int, value: int64) =
  let encoded = uint32(int32(value))
  let position = 4 * cell
  output[position] = uint8(encoded and 255)
  output[position + 1] = uint8((encoded shr 8) and 255)
  output[position + 2] = uint8((encoded shr 16) and 255)
  output[position + 3] = uint8((encoded shr 24) and 255)

proc ones_minus_zeros*(values: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "ones_minus_zeros".} =
  if values.isNil or length < 2 or values[0] < 1 or values[0] > MaxDimension or
      values[1] < 1 or values[1] > MaxDimension: return -1
  let rows = int(values[0])
  let columns = int(values[1])
  if rows > MaxCells div columns: return -1
  let cells = rows * columns
  if length != csize_t(2 + cells): return -1
  for cell in 0 ..< cells:
    if values[2 + cell] != 0 and values[2 + cell] != 1: return -1
  let required = csize_t(4 * cells)
  if output.isNil or outputCapacity < required: return -2

  for byte in 0 ..< 4 * cells: output[byte] = 0
  var rowZeroOnes = 0'i64
  var columnZeroOnes = 0'i64
  for row in 0 ..< rows:
    for column in 0 ..< columns:
      if values[2 + row * columns + column] == 0: continue
      if row == 0:
        inc rowZeroOnes
      else:
        let slot = row * columns
        writeI32(output, slot, readCount(output, slot) + 1)
      if column == 0:
        inc columnZeroOnes
      else:
        writeI32(output, column, readCount(output, column) + 1)

  for row in countdown(rows - 1, 1):
    let rowSlot = row * columns
    let rowOnes = readCount(output, rowSlot)
    for column in 0 ..< columns:
      let columnOnes = if column == 0: columnZeroOnes else: readCount(output, column)
      let difference = 2 * rowOnes + 2 * columnOnes - int64(rows) - int64(columns)
      writeI32(output, rowSlot + column, difference)
  for column in 0 ..< columns:
    let columnOnes = if column == 0: columnZeroOnes else: readCount(output, column)
    let difference = 2 * rowZeroOnes + 2 * columnOnes - int64(rows) - int64(columns)
    writeI32(output, column, difference)
  int64(cells)
