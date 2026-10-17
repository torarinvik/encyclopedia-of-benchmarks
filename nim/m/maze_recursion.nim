const GridRows = 8
const GridCols = 7
const GridCells = GridRows * GridCols
const InputWords = 1 + GridCells
const OutputBytes = 4 * InputWords
const StartIndex = 1 * GridCols + 1
const TargetIndex = 6 * GridCols + 5

type
  I64Input = ptr UncheckedArray[int64]
  U8Output = ptr UncheckedArray[uint8]

proc mazeRecursionSolve(grid: var array[GridCells, uint8], row, col: int,
    strategy: int64): bool =
  if grid[TargetIndex] == 2'u8:
    return true
  let index = row * GridCols + col
  if grid[index] != 0'u8:
    return false
  grid[index] = 2

  if strategy == 0:
    if mazeRecursionSolve(grid, row + 1, col, strategy): return true
    if mazeRecursionSolve(grid, row, col + 1, strategy): return true
    if mazeRecursionSolve(grid, row - 1, col, strategy): return true
    if mazeRecursionSolve(grid, row, col - 1, strategy): return true
  else:
    if mazeRecursionSolve(grid, row - 1, col, strategy): return true
    if mazeRecursionSolve(grid, row, col + 1, strategy): return true
    if mazeRecursionSolve(grid, row + 1, col, strategy): return true
    if mazeRecursionSolve(grid, row, col - 1, strategy): return true

  grid[index] = 3
  false

proc putI32Le(output: U8Output, offset: int, value: int32) =
  let bits = cast[uint32](value)
  for byte in 0..<4:
    output[offset + byte] = uint8((bits shr (8 * byte)) and 0xFF'u32)

proc maze_recursion*(input: I64Input, length: csize_t, output: U8Output,
    capacity: csize_t): int64
    {.cdecl, exportc: "maze_recursion".} =
  if input == nil or length != csize_t(InputWords):
    return -1
  if input[0] < 0 or input[0] > 1:
    return -1
  let strategy = input[0]

  var grid: array[GridCells, uint8]
  for index in 0..<GridCells:
    let cell = input[index + 1]
    if cell != 0 and cell != 1:
      return -1
    grid[index] = uint8(cell)
  for row in 0..<GridRows:
    for col in 0..<GridCols:
      if (row == 0 or row == GridRows - 1 or col == 0 or col == GridCols - 1) and
          grid[row * GridCols + col] != 1'u8:
        return -1
  if grid[StartIndex] != 0'u8 or grid[TargetIndex] != 0'u8:
    return -1
  if output == nil or capacity < csize_t(OutputBytes):
    return -2

  let found = mazeRecursionSolve(grid, 1, 1, strategy)
  var buffer: array[OutputBytes, uint8]
  let out = cast[U8Output](addr buffer[0])
  putI32Le(out, 0, if found: 1'i32 else: 0'i32)
  for index in 0..<GridCells:
    putI32Le(out, 4 * (index + 1), int32(grid[index]))
  for index in 0..<OutputBytes:
    output[index] = buffer[index]
  int64(OutputBytes)
