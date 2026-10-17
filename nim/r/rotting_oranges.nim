const MaxCells = 256
const MaxInputLength = 259
const InvalidResult = low(int64)

proc rotting_oranges*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "rotting_oranges".} =
  if input.isNil:
    if length == 0: return 0
    return InvalidResult
  if length == 0: return 0
  if length < 2 or length > MaxInputLength: return InvalidResult
  if input[0] == 0:
    if input[1] == 0 and length == 2: return 0
    return InvalidResult
  if input[0] < 1 or input[0] > 16 or input[1] < 0 or input[1] > 16:
    return InvalidResult

  let rows = int(input[0])
  let columns = int(input[1])
  let cellCount = rows * columns
  if int(length) != 2 + cellCount: return InvalidResult

  var cells: array[MaxCells, uint8]
  var queue: array[MaxCells, int]
  var distance: array[MaxCells, int]
  var head = 0
  var tail = 0
  var fresh = 0
  var rotted = 0
  for index in 0 ..< cellCount:
    let value = input[2 + index]
    if value < 0 or value > 2: return InvalidResult
    cells[index] = uint8(value)
    if value == 1:
      inc fresh
    elif value == 2:
      queue[tail] = index
      inc tail
  if columns == 0 or fresh == 0: return 0

  var minutes = 0
  while head < tail:
    let index = queue[head]
    inc head
    let row = index div columns
    let column = index mod columns
    let nextDistance = distance[index] + 1
    if row > 0:
      let next = index - columns
      if cells[next] == 1:
        cells[next] = 2
        distance[next] = nextDistance
        minutes = max(minutes, nextDistance)
        inc rotted
        queue[tail] = next
        inc tail
    if column + 1 < columns:
      let next = index + 1
      if cells[next] == 1:
        cells[next] = 2
        distance[next] = nextDistance
        minutes = max(minutes, nextDistance)
        inc rotted
        queue[tail] = next
        inc tail
    if row + 1 < rows:
      let next = index + columns
      if cells[next] == 1:
        cells[next] = 2
        distance[next] = nextDistance
        minutes = max(minutes, nextDistance)
        inc rotted
        queue[tail] = next
        inc tail
    if column > 0:
      let next = index - 1
      if cells[next] == 1:
        cells[next] = 2
        distance[next] = nextDistance
        minutes = max(minutes, nextDistance)
        inc rotted
        queue[tail] = next
        inc tail
  if rotted == fresh: return int64(minutes)
  -1
