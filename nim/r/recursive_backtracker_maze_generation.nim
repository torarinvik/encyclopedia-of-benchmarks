type I64Input = ptr UncheckedArray[int64]
type ByteOutput = ptr UncheckedArray[uint8]

proc recursive_backtracker_maze_generation*(input: I64Input, length: csize_t,
    output: ByteOutput, capacity: csize_t): int64
    {.cdecl, exportc: "recursive_backtracker_maze_generation".} =
  if input.isNil or length < 4 or length > 68: return -1
  let rowsWord = input[0]
  let colsWord = input[1]
  let startWord = input[2]
  let drawsWord = input[3]
  if rowsWord < 1 or rowsWord > 64 or colsWord < 1 or colsWord > 64: return -1
  let rows = int(rowsWord)
  let cols = int(colsWord)
  let cells = rows * cols
  if cells > 64 or startWord < 0 or startWord >= int64(cells) or
      drawsWord != int64(cells - 1) or length != csize_t(4 + cells - 1): return -1
  for i in 0 ..< cells - 1:
    if input[4 + i] < 0 or input[4 + i] > 3: return -1

  var visited: array[64, bool]
  var walls: array[64, uint8]
  var stack: array[64, int]
  for cell in 0 ..< cells: walls[cell] = 15
  var depth = 1
  var cursor = 0
  stack[0] = int(startWord)
  visited[stack[0]] = true
  while depth > 0:
    let cell = stack[depth - 1]
    let row = cell div cols
    let col = cell mod cols
    var nextCells: array[4, int]
    var directions: array[4, int]
    var count = 0
    if row > 0 and not visited[cell - cols]:
      nextCells[count] = cell - cols; directions[count] = 0; inc count
    if col + 1 < cols and not visited[cell + 1]:
      nextCells[count] = cell + 1; directions[count] = 1; inc count
    if row + 1 < rows and not visited[cell + cols]:
      nextCells[count] = cell + cols; directions[count] = 2; inc count
    if col > 0 and not visited[cell - 1]:
      nextCells[count] = cell - 1; directions[count] = 3; inc count
    if count == 0:
      dec depth
      continue
    if cursor >= cells - 1: return -1
    let choice = int(input[4 + cursor])
    inc cursor
    if choice >= count: return -1
    let next = nextCells[choice]
    let direction = directions[choice]
    visited[next] = true
    walls[cell] = walls[cell] and uint8(15 - (1 shl direction))
    walls[next] = walls[next] and uint8(15 - (1 shl ((direction + 2) mod 4)))
    stack[depth] = next
    inc depth
  if cursor != cells - 1: return -1
  for cell in 0 ..< cells:
    if not visited[cell]: return -1
  if output.isNil or capacity < csize_t(cells): return -2
  for cell in 0 ..< cells: output[cell] = walls[cell]
  int64(cells)
