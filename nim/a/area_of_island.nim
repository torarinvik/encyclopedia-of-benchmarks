## Return the size of the largest four-connected nonzero region.
proc area_of_island*(input: ptr UncheckedArray[int64], length: csize_t): int64 {.cdecl, exportc: "area_of_island".} =
  const maxRows = 64
  const maxColumns = 64
  const maxCells = maxRows * maxColumns
  if input == nil or length < 2 or input[0] < 1 or input[0] > int64(maxRows) or
      input[1] < 0 or input[1] > int64(maxColumns):
    return -1
  let rows = int(input[0])
  let columns = int(input[1])
  let cells = rows * columns
  if int(length) != cells + 2: return -1

  var visited: array[maxCells, bool]
  var stack: array[maxCells, int]
  var maximumArea = 0
  for start in 0 ..< cells:
    if input[2 + start] == 0 or visited[start]: continue
    var top = 0
    var area = 0
    visited[start] = true
    stack[top] = start
    inc top
    while top > 0:
      dec top
      let current = stack[top]
      inc area
      let row = current div columns
      let column = current mod columns
      template pushIfLand(neighbor: int) =
        if not visited[neighbor] and input[2 + neighbor] != 0:
          visited[neighbor] = true
          stack[top] = neighbor
          inc top
      if row > 0: pushIfLand(current - columns)
      if column + 1 < columns: pushIfLand(current + 1)
      if row + 1 < rows: pushIfLand(current + columns)
      if column > 0: pushIfLand(current - 1)
    maximumArea = max(maximumArea, area)
  return int64(maximumArea)
