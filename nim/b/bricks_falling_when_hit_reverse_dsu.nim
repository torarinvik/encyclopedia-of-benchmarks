const
  MaxCells = 64
  MaxHits = 16
  MaxInputLength = 100

type
  I64Input = ptr UncheckedArray[int64]
  U8Output = ptr UncheckedArray[uint8]
  Grid = array[MaxCells, uint8]
  Parent = array[MaxCells + 1, int32]
  ComponentSizes = array[MaxCells + 1, int32]

proc findRoot(parent: var Parent, vertexInput: int): int =
  var vertex = vertexInput
  while int(parent[vertex]) != vertex:
    parent[vertex] = parent[int(parent[vertex])]
    vertex = int(parent[vertex])
  vertex

proc unite(parent: var Parent, componentSize: var ComponentSizes, left, right: int) =
  var a = findRoot(parent, left)
  var b = findRoot(parent, right)
  if a == b: return
  if componentSize[a] < componentSize[b]: swap(a, b)
  parent[b] = int32(a)
  componentSize[a] += componentSize[b]

proc buildDsu(grid: var Grid, rows, columns: int,
    parent: var Parent, componentSize: var ComponentSizes) =
  let cells = rows * columns
  for cell in 0 ..< cells:
    parent[cell] = int32(cell)
    componentSize[cell] = int32(grid[cell])
  parent[cells] = int32(cells)
  componentSize[cells] = 0
  for cell in 0 ..< cells:
    if grid[cell] == 0: continue
    let row = cell div columns
    let column = cell mod columns
    if row == 0: unite(parent, componentSize, cell, cells)
    if row > 0 and grid[cell - columns] != 0: unite(parent, componentSize, cell, cell - columns)
    if column > 0 and grid[cell - 1] != 0: unite(parent, componentSize, cell, cell - 1)

proc putI64Le(output: U8Output, offset: int, value: int32) =
  let bits = uint64(value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8((bits shr (8 * byte)) and 0xFF'u64)

proc bricks_falling_when_hit_reverse_dsu*(input: I64Input, length: csize_t,
    output: U8Output, capacity: csize_t): int64
    {.cdecl, exportc: "bricks_falling_when_hit_reverse_dsu".} =
  if input.isNil or length < 3 or length > csize_t(MaxInputLength): return -1
  let rowValue = input[0]
  let columnValue = input[1]
  let hitValue = input[2]
  if rowValue < 1 or rowValue > 8 or columnValue < 1 or columnValue > 8 or hitValue < 0 or hitValue > MaxHits: return -1
  let rows = int(rowValue)
  let columns = int(columnValue)
  let cells = rows * columns
  let hits = int(hitValue)
  if hits > cells or int(length) != 3 + cells + 2 * hits: return -1

  var grid: Grid
  var parent: Parent
  var componentSize: ComponentSizes
  for cell in 0 ..< cells:
    let value = input[3 + cell]
    if value != 0 and value != 1: return -1
    grid[cell] = uint8(value)
  let hitStart = 3 + cells
  for index in 0 ..< hits:
    let row = input[hitStart + 2 * index]
    let column = input[hitStart + 2 * index + 1]
    if row < 0 or row >= rowValue or column < 0 or column >= columnValue: return -1
    for previous in 0 ..< index:
      if input[hitStart + 2 * previous] == row and input[hitStart + 2 * previous + 1] == column: return -1

  buildDsu(grid, rows, columns, parent, componentSize)
  let roofRoot = findRoot(parent, cells)
  for cell in 0 ..< cells:
    if grid[cell] != 0 and findRoot(parent, cell) != roofRoot: return -1

  let required = hits * 8
  if capacity < csize_t(required) or (required > 0 and output.isNil): return -2
  if hits == 0: return 0
  for index in 0 ..< hits:
    let row = int(input[hitStart + 2 * index])
    let column = int(input[hitStart + 2 * index + 1])
    grid[row * columns + column] = 0
  buildDsu(grid, rows, columns, parent, componentSize)

  for reverse in 0 ..< hits:
    let index = hits - 1 - reverse
    let row = int(input[hitStart + 2 * index])
    let column = int(input[hitStart + 2 * index + 1])
    let cell = row * columns + column
    if input[3 + cell] == 0:
      putI64Le(output, index * 8, 0)
      continue
    let before = componentSize[findRoot(parent, cells)]
    grid[cell] = 1
    parent[cell] = int32(cell)
    componentSize[cell] = 1
    if row == 0: unite(parent, componentSize, cell, cells)
    if row > 0 and grid[cell - columns] != 0: unite(parent, componentSize, cell, cell - columns)
    if row + 1 < rows and grid[cell + columns] != 0: unite(parent, componentSize, cell, cell + columns)
    if column > 0 and grid[cell - 1] != 0: unite(parent, componentSize, cell, cell - 1)
    if column + 1 < columns and grid[cell + 1] != 0: unite(parent, componentSize, cell, cell + 1)
    let after = componentSize[findRoot(parent, cells)]
    let fallen = if after > before + 1: after - before - 1 else: 0'i32
    putI64Le(output, index * 8, fallen)
  int64(required)
