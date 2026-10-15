const MaxNodes = 256
const Dx: array[8, int] = [-1, -1, -1, 0, 0, 1, 1, 1]
const Dy: array[8, int] = [-1, 0, 1, -1, 1, -1, 0, 1]

type SearchNode = object
  x, y, g, f, parent: int

proc writeI64(output: ptr UncheckedArray[uint8], position: var int, value: int64) =
  let bits = cast[uint64](value)
  for shift in countup(0, 56, 8):
    output[position] = uint8((bits shr shift) and 255)
    inc position

proc astar*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64 {.cdecl, exportc: "astar".} =
  if input.isNil or length != 6: return -1
  let rows64 = input[0]
  let cols64 = input[1]
  let sx64 = input[2]
  let sy64 = input[3]
  let gx64 = input[4]
  let gy64 = input[5]
  if rows64 < 1 or rows64 > 16 or cols64 < 1 or cols64 > 16 or
      sx64 < 0 or sx64 >= rows64 or sy64 < 0 or sy64 >= cols64 or
      gx64 < 0 or gx64 >= rows64 or gy64 < 0 or gy64 >= cols64:
    return -1
  let rows = int(rows64)
  let cols = int(cols64)
  let sx = int(sx64)
  let sy = int(sy64)
  let gx = int(gx64)
  let gy = int(gy64)
  var nodes: array[MaxNodes, SearchNode]
  var open: array[MaxNodes, int]
  var nodeCount = 1
  var openCount = 1
  nodes[0] = SearchNode(x: sx, y: sy, g: 0, f: 0, parent: -1)
  open[0] = 0
  var current = 0
  var found = false
  while openCount > 0:
    var best = 0
    for i in 1 ..< openCount:
      if nodes[open[i]].f < nodes[open[best]].f: best = i
    current = open[best]
    for i in best + 1 ..< openCount: open[i - 1] = open[i]
    dec openCount
    let currentNode = nodes[current]
    if currentNode.x == gx and currentNode.y == gy:
      found = true
      break
    for neighbor in 0 ..< 8:
      let x = currentNode.x + Dx[neighbor]
      let y = currentNode.y + Dy[neighbor]
      if x < 0 or x >= rows or y < 0 or y >= cols: continue
      if nodeCount >= MaxNodes or openCount >= MaxNodes: return -1
      let g = currentNode.g + 1
      let ex = gx - x
      let ey = gy - y
      nodes[nodeCount] = SearchNode(x: x, y: y, g: g, f: g + ex * ex + ey * ey, parent: current)
      open[openCount] = nodeCount
      inc openCount
      inc nodeCount
  if not found: return -1
  var pathCount = 0
  var cursor = current
  while cursor >= 0:
    inc pathCount
    cursor = nodes[cursor].parent
  let outputBytes = pathCount * 16
  if output.isNil or capacity < csize_t(outputBytes): return -2
  var offset = outputBytes
  cursor = current
  while cursor >= 0:
    offset -= 16
    writeI64(output, offset, int64(nodes[cursor].x))
    writeI64(output, offset + 8, int64(nodes[cursor].y))
    cursor = nodes[cursor].parent
  int64(outputBytes)
