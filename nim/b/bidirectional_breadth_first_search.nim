import core:c

const
  MaxDimension = 8
  MaxCells = MaxDimension * MaxDimension
  MaxInputLength = 5 + MaxCells
  MaxOutputValues = 1 + MaxCells

type I64Input = ptr UncheckedArray[int64]
type ByteOutput = ptr UncheckedArray[uint8]

proc putI64(output: ByteOutput, offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8((bits shr (8 * byte)) and 255)

proc bidirectional_breadth_first_search*(input: I64Input, length: csize_t,
    output: ByteOutput, capacity: csize_t): int64 {.cdecl, exportc: "bidirectional_breadth_first_search".} =
  if input.isNil or length < 5 or length > csize_t(MaxInputLength): return -1
  let rows64 = input[0]
  let cols64 = input[1]
  if rows64 < 1 or rows64 > int64(MaxDimension) or cols64 < 1 or cols64 > int64(MaxDimension): return -1
  let rows = int(rows64)
  let cols = int(cols64)
  let cells = rows * cols
  let start64 = input[2]
  let goal64 = input[3]
  let blockedCount64 = input[4]
  if start64 < 0 or start64 >= int64(cells) or goal64 < 0 or goal64 >= int64(cells) or blockedCount64 < 0 or blockedCount64 > int64(cells): return -1
  let blockedCount = int(blockedCount64)
  if length != csize_t(5 + blockedCount): return -1
  let start = int(start64)
  let goal = int(goal64)
  var blocked: array[MaxCells, bool]
  for index in 0 ..< blockedCount:
    let value = input[5 + index]
    if value < 0 or value >= int64(cells): return -1
    let cell = int(value)
    if blocked[cell]: return -1
    blocked[cell] = true
  if blocked[start] or blocked[goal]: return -1

  var distance: array[2 * MaxCells, int64]
  var parent: array[2 * MaxCells, int64]
  for index in 0 ..< 2 * MaxCells:
    distance[index] = -1
    parent[index] = -1
  var queues: array[2 * MaxCells, int]
  var head: array[2, int]
  var tail: array[2, int]
  tail[0] = 1
  tail[1] = 1
  distance[start] = 0
  distance[MaxCells + goal] = 0
  queues[0] = start
  queues[MaxCells] = goal
  var meeting = if start == goal: start else: -1
  while meeting < 0 and head[0] < tail[0] and head[1] < tail[1]:
    for side in 0 ..< 2:
      if meeting >= 0: break
      let layerEnd = tail[side]
      while head[side] < layerEnd:
        let node = queues[side * MaxCells + head[side]]
        inc head[side]
        let row = node div cols
        let col = node mod cols
        var neighbors: array[4, int]
        neighbors[0] = -1
        neighbors[1] = -1
        neighbors[2] = -1
        neighbors[3] = -1
        if row > 0: neighbors[0] = node - cols
        if col > 0: neighbors[1] = node - 1
        if row + 1 < rows: neighbors[2] = node + cols
        if col + 1 < cols: neighbors[3] = node + 1
        for neighbor in neighbors:
          if neighbor < 0 or blocked[neighbor] or distance[side * MaxCells + neighbor] >= 0: continue
          distance[side * MaxCells + neighbor] = distance[side * MaxCells + node] + 1
          parent[side * MaxCells + neighbor] = int64(node)
          queues[side * MaxCells + tail[side]] = neighbor
          inc tail[side]
          if distance[(1 - side) * MaxCells + neighbor] >= 0:
            meeting = neighbor
            break
        if meeting >= 0: break
  var encoded: array[MaxOutputValues, int64]
  var valueCount = 1
  if meeting < 0:
    encoded[0] = 0
  else:
    var reversePath: array[MaxCells, int]
    var prefixCount = 0
    var current = meeting
    while current >= 0:
      reversePath[prefixCount] = current
      inc prefixCount
      if current == start: break
      current = int(parent[current])
    var pathCount = 0
    for index in 0 ..< prefixCount:
      encoded[1 + pathCount] = int64(reversePath[prefixCount - 1 - index])
      inc pathCount
    current = int(parent[MaxCells + meeting])
    while current >= 0:
      encoded[1 + pathCount] = int64(current)
      inc pathCount
      current = int(parent[MaxCells + current])
    encoded[0] = int64(pathCount)
    valueCount += pathCount
  let required = valueCount * 8
  if output.isNil or capacity < csize_t(required): return -2
  for index in 0 ..< valueCount: putI64(output, index * 8, encoded[index])
  int64(required)
