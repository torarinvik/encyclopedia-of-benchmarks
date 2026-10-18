const MaxDimension = 4
const MaxCells = MaxDimension * MaxDimension
const MaxPaths = 184
const MaxPathLength = MaxCells - 1
const MaxParseableInputLength = 19
const MaxOutputWords = 2097
const MaxOutputBytes = MaxOutputWords * 8

type
  Maze = object
    variant: int
    size: int
    cells: array[MaxCells, int64]
  Paths = object
    directions: array[MaxPaths, array[MaxPathLength, uint8]]
    lengths: array[MaxPaths, int]
    count: int

proc parseMaze(values: ptr UncheckedArray[int64], length: int, maze: var Maze): bool =
  if values == nil or length < 1 or length > MaxParseableInputLength: return false
  if length < 2 or (values[0] != 0 and values[0] != 1): return false
  if values[1] < 1 or values[1] > MaxDimension: return false
  let size = int(values[1])
  if length != 2 + size * size: return false
  maze.variant = int(values[0])
  maze.size = size
  for index in 0 ..< size * size:
    let cell = values[2 + index]
    if cell != 0 and cell != 1: return false
    maze.cells[index] = cell
  true

proc collectPaths(maze: Maze, row, col: int, visited: var array[MaxCells, bool],
                  current: var array[MaxPathLength, uint8], pathLength: int,
                  paths: var Paths): bool =
  if row == maze.size - 1 and col == maze.size - 1:
    let slot = paths.count
    inc paths.count
    paths.lengths[slot] = pathLength
    for index in 0 ..< pathLength:
      paths.directions[slot][index] = current[index]
    return maze.variant == 1

  let index = row * maze.size + col
  visited[index] = true
  for movement in 0 ..< 4:
    var deltaRow, deltaCol: int
    var code: uint8
    if maze.variant == 0:
      case movement
      of 0: (deltaRow, deltaCol, code) = (1, 0, 0'u8)
      of 1: (deltaRow, deltaCol, code) = (0, -1, 1'u8)
      of 2: (deltaRow, deltaCol, code) = (0, 1, 2'u8)
      else: (deltaRow, deltaCol, code) = (-1, 0, 3'u8)
    else:
      case movement
      of 0: (deltaRow, deltaCol, code) = (0, 1, 2'u8)
      of 1: (deltaRow, deltaCol, code) = (1, 0, 0'u8)
      of 2: (deltaRow, deltaCol, code) = (-1, 0, 3'u8)
      else: (deltaRow, deltaCol, code) = (0, -1, 1'u8)
    let nextRow = row + deltaRow
    let nextCol = col + deltaCol
    if nextRow < 0 or nextCol < 0 or nextRow >= maze.size or nextCol >= maze.size: continue
    let nextIndex = nextRow * maze.size + nextCol
    if maze.cells[nextIndex] != 1 or visited[nextIndex]: continue
    current[pathLength] = code
    if collectPaths(maze, nextRow, nextCol, visited, current, pathLength + 1, paths):
      visited[index] = false
      return true
  visited[index] = false
  false

proc writeI64Le(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  var bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8(bits and 0xff'u64)
    bits = bits shr 8

proc rat_in_amaze*(input: ptr UncheckedArray[int64], inputLength: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "rat_in_amaze".} =
  if input == nil or inputLength < 1 or inputLength > MaxParseableInputLength.csize_t: return -1
  var maze: Maze
  if not parseMaze(input, int(inputLength), maze): return -1

  var paths: Paths
  if maze.cells[0] == 1 and maze.cells[maze.size * maze.size - 1] == 1:
    var visited: array[MaxCells, bool]
    var current: array[MaxPathLength, uint8]
    discard collectPaths(maze, 0, 0, visited, current, 0, paths)
  if paths.count == 0: return -3

  var outputWords = 1
  for path in 0 ..< paths.count:
    outputWords += 1 + paths.lengths[path]
  let outputBytes = outputWords * 8
  if outputBytes > MaxOutputBytes: return -1
  if output == nil or outputCapacity < outputBytes.csize_t: return -2

  var offset = 0
  writeI64Le(output, offset, paths.count.int64)
  offset += 8
  for path in 0 ..< paths.count:
    writeI64Le(output, offset, paths.lengths[path].int64)
    offset += 8
    for movement in 0 ..< paths.lengths[path]:
      writeI64Le(output, offset, paths.directions[path][movement].int64)
      offset += 8
  outputBytes.int64
