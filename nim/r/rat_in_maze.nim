const MaxDimension = 8
const MaxCells = MaxDimension * MaxDimension
const MaxParseableInputLength = 71
const MaxOutputBytes = MaxCells * 8

type Maze = object
  variant: int
  rows: int
  cols: int
  startRow: int
  startCol: int
  destinationRow: int
  destinationCol: int
  cells: array[MaxCells, int64]

proc parseMaze(values: ptr UncheckedArray[int64], length: int, maze: var Maze): bool =
  if values == nil or length < 1 or length > MaxParseableInputLength: return false
  if values[0] == 0:
    if length < 7 or values[1] < 1 or values[1] > MaxDimension: return false
    let size = int(values[1])
    if length != 6 + size * size: return false
    for index in 2 .. 5:
      if values[index] < 0 or values[index] >= size: return false
    maze.variant = 0
    maze.rows = size
    maze.cols = size
    maze.startRow = int(values[2])
    maze.startCol = int(values[3])
    maze.destinationRow = int(values[4])
    maze.destinationCol = int(values[5])
    for index in 0 ..< size * size:
      let cell = values[6 + index]
      if cell != 0 and cell != 1: return false
      maze.cells[index] = cell
  elif values[0] == 1:
    if length < 6 or values[1] < 1 or values[1] > MaxDimension or
        values[2] < 1 or values[2] > MaxDimension: return false
    let rows = int(values[1])
    let cols = int(values[2])
    if length != 5 + rows * cols or values[3] < 0 or values[3] >= rows or
        values[4] < 0 or values[4] >= cols: return false
    maze.variant = 1
    maze.rows = rows
    maze.cols = cols
    maze.startRow = int(values[3])
    maze.startCol = int(values[4])
    maze.destinationRow = rows - 1
    maze.destinationCol = cols - 1
    for index in 0 ..< rows * cols:
      let cell = values[5 + index]
      if cell != 0 and cell != 1: return false
      maze.cells[index] = cell
  else:
    return false
  true

proc searchPath(maze: Maze, row, col: int, path: var array[MaxCells, bool]): bool

proc searchPath(maze: Maze, row, col: int, path: var array[MaxCells, bool]): bool =
  if maze.variant == 1 and row == maze.destinationRow and col == maze.destinationCol:
    path[row * maze.cols + col] = true
    return true
  if row < 0 or col < 0 or row >= maze.rows or col >= maze.cols: return false
  let index = row * maze.cols + col
  let openValue = if maze.variant == 0: 0'i64 else: 1'i64
  if maze.cells[index] != openValue or path[index]: return false
  path[index] = true
  if maze.variant == 0 and row == maze.destinationRow and col == maze.destinationCol: return true

  for movement in 0 ..< 4:
    var deltaRow, deltaCol: int
    if maze.variant == 0:
      case movement
      of 0: (deltaRow, deltaCol) = (1, 0)
      of 1: (deltaRow, deltaCol) = (0, 1)
      of 2: (deltaRow, deltaCol) = (-1, 0)
      else: (deltaRow, deltaCol) = (0, -1)
    else:
      case movement
      of 0: (deltaRow, deltaCol) = (0, 1)
      of 1: (deltaRow, deltaCol) = (1, 0)
      of 2: (deltaRow, deltaCol) = (0, -1)
      else: (deltaRow, deltaCol) = (-1, 0)
    if searchPath(maze, row + deltaRow, col + deltaCol, path): return true
  path[index] = false
  false

proc writeI64Le(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  var bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8(bits and 0xff'u64)
    bits = bits shr 8

proc rat_in_maze*(input: ptr UncheckedArray[int64], inputLength: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "rat_in_maze".} =
  if input == nil or inputLength < 1 or inputLength > MaxParseableInputLength.csize_t: return -1
  var maze: Maze
  if not parseMaze(input, int(inputLength), maze): return -1
  var path: array[MaxCells, bool]
  if not searchPath(maze, maze.startRow, maze.startCol, path): return -3

  let cells = maze.rows * maze.cols
  let outputBytes = cells * 8
  if outputBytes > MaxOutputBytes: return -1
  if output == nil or outputCapacity < outputBytes.csize_t: return -2
  for index in 0 ..< cells:
    var value = 0'i64
    if maze.variant == 0:
      if not path[index]: value = 1
    elif path[index]:
      value = 1
    writeI64Le(output, index * 8, value)
  outputBytes.int64
