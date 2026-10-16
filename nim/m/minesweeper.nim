const MaxDim = 32
const MaxCells = MaxDim * MaxDim
const MaxOutput = 8 + 8 * MaxCells

proc writeI64(output: var array[MaxOutput, uint8], position: int, value: int64): int =
  let bits = cast[uint64](value)
  for i in 0 ..< 8: output[position + i] = uint8((bits shr (8 * i)) and 255'u64)
  position + 8

proc minesweeper*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "minesweeper".} =
  if input.isNil or length < 2 or length > csize_t(2 + MaxCells): return -1
  let rowsValue = input[0]
  let colsValue = input[1]
  if rowsValue < 1 or rowsValue > int64(MaxDim) or colsValue < 1 or colsValue > int64(MaxDim): return -1
  let rows = int(rowsValue)
  let cols = int(colsValue)
  let count = rows * cols
  if length != csize_t(2 + count): return -1
  var cells: array[MaxCells, uint8]
  for i in 0 ..< count:
    if input[2 + i] != 0 and input[2 + i] != 1: return -1
    cells[i] = uint8(input[2 + i])
  var neighbors: array[MaxCells, int64]
  for row in 0 ..< rows:
    for col in 0 ..< cols:
      var mines = 0'i64
      for dr in -1 .. 1:
        for dc in -1 .. 1:
          if dr == 0 and dc == 0: continue
          let nr = row + dr
          let nc = col + dc
          if nr >= 0 and nr < rows and nc >= 0 and nc < cols and cells[nr * cols + nc] == 1: inc mines
      neighbors[row * cols + col] = mines
  let needed = 8 + 8 * count
  if output.isNil or outputCapacity < csize_t(needed): return -2
  var payload: array[MaxOutput, uint8]
  var written = writeI64(payload, 0, int64(count))
  for i in 0 ..< count: written = writeI64(payload, written, neighbors[i])
  copyMem(output, addr payload[0], written)
  int64(written)
