type I64Input = ptr UncheckedArray[int64]

proc grid_shortest_path_obstacle_elimination*(values: I64Input, length: csize_t): int64
    {.cdecl, exportc: "grid_shortest_path_obstacle_elimination".} =
  if values.isNil or length < 3 or length > 40: return -2
  let rows = values[0]
  let columns = values[1]
  let budget = values[2]
  if rows < 1 or rows > 6 or columns < 1 or columns > 6 or budget < 0 or budget > 6: return -2
  if length != csize_t(3 + rows * columns): return -2

  let cellCount = int(rows * columns)
  var cells: array[36, int64]
  for cell in 0 ..< cellCount:
    let value = values[3 + cell]
    if value != 0 and value != 1: return -2
    cells[cell] = value
  if cells[0] != 0 or cells[cellCount - 1] != 0: return -2

  let stride = int(budget + 1)
  let stateCount = cellCount * stride
  var queue: array[252, int]
  var distance: array[252, int64]
  for state in 0 ..< stateCount: distance[state] = -1
  let start = int(budget)
  var head = 0
  var tail = 1
  queue[0] = start
  distance[start] = 0

  while head < tail:
    let state = queue[head]
    inc head
    let cell = state div stride
    let remaining = state mod stride
    if cell + 1 == cellCount: return distance[state]
    let row = cell div int(columns)
    let column = cell mod int(columns)
    let nextRows = [row - 1, row, row, row + 1]
    let nextColumns = [column, column - 1, column + 1, column]
    for direction in 0 .. 3:
      let nextRow = nextRows[direction]
      let nextColumn = nextColumns[direction]
      if nextRow < 0 or nextRow >= int(rows) or nextColumn < 0 or nextColumn >= int(columns): continue
      let nextCell = nextRow * int(columns) + nextColumn
      let nextRemaining = remaining - int(cells[nextCell])
      if nextRemaining < 0: continue
      let nextState = nextCell * stride + nextRemaining
      if distance[nextState] != -1: continue
      distance[nextState] = distance[state] + 1
      queue[tail] = nextState
      inc tail
  -1
