const MaxRows = 8
const MaxCols = 8
const MaxCells = 64
const MaxInput = 66

proc heapPush(heap: var array[MaxCells, int64], size: var int, key: int64) =
  var position = size
  inc size
  while position > 0:
    let parent = (position - 1) div 2
    if heap[parent] <= key: break
    heap[position] = heap[parent]
    position = parent
  heap[position] = key

proc heapPop(heap: var array[MaxCells, int64], size: var int): int64 =
  let minimum = heap[0]
  dec size
  if size > 0:
    let last = heap[size]
    var position = 0
    while 2 * position + 1 < size:
      var child = 2 * position + 1
      if child + 1 < size and heap[child + 1] < heap[child]: inc child
      if heap[child] >= last: break
      heap[position] = heap[child]
      position = child
    heap[position] = last
  minimum

proc trapping_rain_water_ii*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "trapping_rain_water_ii".} =
  if input.isNil or length < 2 or length > csize_t(MaxInput): return -1
  if input[0] < 1 or input[0] > MaxRows or input[1] < 1 or input[1] > MaxCols: return -1
  let rows = int(input[0])
  let cols = int(input[1])
  if length != csize_t(2 + rows * cols): return -1
  var heights: array[MaxCells, int64]
  for cell in 0 ..< rows * cols:
    let height = input[2 + cell]
    if height < 0 or height > 1000: return -1
    heights[cell] = height

  var visited: array[MaxCells, bool]
  var heap: array[MaxCells, int64]
  var heapSize = 0
  for row in 0 ..< rows:
    for col in 0 ..< cols:
      if row == 0 or row + 1 == rows or col == 0 or col + 1 == cols:
        let cell = row * cols + col
        if not visited[cell]:
          visited[cell] = true
          heapPush(heap, heapSize, heights[cell] * 64 + int64(cell))

  const dr = [-1, 1, 0, 0]
  const dc = [0, 0, -1, 1]
  var retained = 0'i64
  while heapSize > 0:
    let key = heapPop(heap, heapSize)
    let level = key div 64
    let cell = int(key mod 64)
    let row = cell div cols
    let col = cell mod cols
    for direction in 0 ..< 4:
      let nr = row + dr[direction]
      let nc = col + dc[direction]
      if nr < 0 or nr >= rows or nc < 0 or nc >= cols: continue
      let neighbor = nr * cols + nc
      if visited[neighbor]: continue
      visited[neighbor] = true
      let height = heights[neighbor]
      if height < level: retained += level - height
      let nextLevel = max(level, height)
      heapPush(heap, heapSize, nextLevel * 64 + int64(neighbor))
  retained
