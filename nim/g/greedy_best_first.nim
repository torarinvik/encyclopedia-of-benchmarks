const MAX_CELLS = 9

proc heuristic(cell, goal, columns: int): int =
  abs(cell div columns - goal div columns) + abs(cell mod columns - goal mod columns)

proc greedy_best_first*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "greedy_best_first".} =
  if values == nil or length < 7 or length > 9:
    return -1
  let rowValue = values[0]
  let columnValue = values[1]
  if rowValue < 1 or rowValue > 3 or columnValue < 1 or columnValue > 3:
    return -1
  let rows = int(rowValue)
  let columns = int(columnValue)
  if length != csize_t(6 + rows):
    return -1
  let startRow = values[2]
  let startColumn = values[3]
  let goalRow = values[4]
  let goalColumn = values[5]
  if startRow < 0 or startRow >= rowValue or goalRow < 0 or goalRow >= rowValue or
      startColumn < 0 or startColumn >= columnValue or goalColumn < 0 or goalColumn >= columnValue:
    return -1
  var masks: array[3, int]
  for row in 0 ..< rows:
    let mask = values[6 + row]
    if mask < 0 or mask >= (1'i64 shl columns):
      return -1
    masks[row] = int(mask)
  let start = int(startRow) * columns + int(startColumn)
  let goal = int(goalRow) * columns + int(goalColumn)
  if (masks[start div columns] and (1 shl (start mod columns))) != 0 or
      (masks[goal div columns] and (1 shl (goal mod columns))) != 0:
    return -1

  var opened: array[MAX_CELLS, int]
  var parent: array[MAX_CELLS, int]
  var closed, inOpen: array[MAX_CELLS, bool]
  for cell in 0 ..< MAX_CELLS:
    parent[cell] = -1
  var openCount = 1
  var found = false
  opened[0] = start
  inOpen[start] = true
  while openCount > 0:
    for index in 1 ..< openCount:
      let current = opened[index]
      var position = index
      while position > 0 and heuristic(opened[position - 1], goal, columns) > heuristic(current, goal, columns):
        opened[position] = opened[position - 1]
        dec position
      opened[position] = current
    let current = opened[0]
    for index in 1 ..< openCount:
      opened[index - 1] = opened[index]
    dec openCount
    inOpen[current] = false
    if current == goal:
      found = true
      break
    closed[current] = true
    let row = current div columns
    let column = current mod columns
    let nextRows = [row - 1, row, row + 1, row]
    let nextColumns = [column, column - 1, column, column + 1]
    for direction in 0 .. 3:
      let nextRow = nextRows[direction]
      let nextColumn = nextColumns[direction]
      if nextRow < 0 or nextRow >= rows or nextColumn < 0 or nextColumn >= columns:
        continue
      let child = nextRow * columns + nextColumn
      if (masks[nextRow] and (1 shl nextColumn)) != 0 or closed[child] or inOpen[child]:
        continue
      parent[child] = current
      opened[openCount] = child
      inc openCount
      inOpen[child] = true

  var path: array[MAX_CELLS, int]
  var pathCount = 0
  if found:
    var current = goal
    while current >= 0 and pathCount < MAX_CELLS:
      path[pathCount] = current
      inc pathCount
      current = parent[current]
  else:
    path[0] = start
    pathCount = 1
  var packed = 0'u64
  for index in 0 ..< pathCount:
    packed = packed or (uint64(path[pathCount - 1 - index] + 1) shl (4 * index))
  int64((uint64(pathCount) shl 36) or packed)
