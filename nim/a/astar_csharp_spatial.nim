import std/math

const MaxNodes = 16
type SpatialNode = object
  x, y, multiplier, current, estimated: float64
  traversable: bool
  state, parent: int

proc distance(nodes: var array[MaxNodes, SpatialNode], a, b: int): float64 =
  let dx = nodes[a].x - nodes[b].x
  let dy = nodes[a].y - nodes[b].y
  sqrt(dx * dx + dy * dy)

proc total(nodes: array[MaxNodes, SpatialNode], i: int): float64 = nodes[i].current + nodes[i].estimated

proc enqueue(heap: var array[MaxNodes, int], count: var int, value: int, nodes: array[MaxNodes, SpatialNode]) =
  var i = count
  inc count
  while i > 0:
    let parent = (i - 1) div 2
    if total(nodes, heap[parent]) <= total(nodes, value): break
    heap[i] = heap[parent]
    i = parent
  heap[i] = value

proc dequeue(heap: var array[MaxNodes, int], count: var int, nodes: array[MaxNodes, SpatialNode]): int =
  result = heap[0]
  dec count
  let root = heap[count]
  var i = 0
  while i * 2 + 1 < count:
    let left = i * 2 + 1
    let right = i * 2 + 2
    let child = if right < count and total(nodes, heap[right]) < total(nodes, heap[left]): right else: left
    if total(nodes, heap[child]) >= total(nodes, root): break
    heap[i] = heap[child]
    i = child
  if count > 0: heap[i] = root

proc putI64Le(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for b in 0..<8: output[offset + b] = uint8((bits shr (b * 8)) and 255'u64)

proc astar_csharp_spatial*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64 {.cdecl, exportc: "astar_csharp_spatial".} =
  if input.isNil or length < 4: return -1
  let n64 = input[0]; let m64 = input[1]; let start64 = input[2]; let goal64 = input[3]
  if n64 < 2 or n64 > MaxNodes or m64 != n64 - 1 or start64 < 0 or start64 >= n64 or goal64 < 0 or goal64 >= n64: return -1
  let n = int(n64); let m = int(m64); let start = int(start64); let goal = int(goal64)
  if int(length) != 4 + 4*n + 2*m: return -1
  let edge = 4 + 4*n
  var nodes: array[MaxNodes, SpatialNode]
  var parents, seen, stack: array[MaxNodes, int]
  for i in 0..<n:
    let o = 4 + 4*i
    let x = input[o]; let y = input[o+1]; let traversable = input[o+2]; let multiplier = input[o+3]
    if x < -1000 or x > 1000 or y < -1000 or y > 1000 or (traversable != 0 and traversable != 1) or multiplier < 1 or multiplier > 4: return -1
    nodes[i] = SpatialNode(x: float64(x), y: float64(y), multiplier: float64(multiplier), traversable: traversable == 1, parent: -1)
    for j in 0..<i: if nodes[i].x == nodes[j].x and nodes[i].y == nodes[j].y: return -1
  for e in 0..<m:
    let u = input[edge + 2*e]; let v = input[edge + 2*e + 1]
    if u < 0 or u >= n64 or v < 0 or v >= n64 or u == v: return -1
    inc parents[int(v)]
    if parents[int(v)] > 1: return -1
    for p in 0..<e: if input[edge+2*p] == u and input[edge+2*p+1] == v: return -1
  if parents[start] != 0: return -1
  for i in 0..<n: if i != start and parents[i] != 1: return -1
  var top = 0; var visited = 0
  stack[top] = start; inc top
  while top > 0:
    dec top
    let u = stack[top]
    if seen[u] != 0: continue
    seen[u] = 1; inc visited
    for e in 0..<m: if input[edge+2*e] == int64(u): stack[top] = int(input[edge+2*e+1]); inc top
  if visited != n: return -1
  var heap: array[MaxNodes, int]; var heapCount = 0
  for e in 0..<m:
    if input[edge+2*e] == int64(start):
      let v = int(input[edge+2*e+1])
      if nodes[v].traversable:
        nodes[v].current = distance(nodes, start, v) * nodes[v].multiplier
        nodes[v].estimated = distance(nodes, v, goal)
        enqueue(heap, heapCount, v, nodes)
  var path: array[MaxNodes, int]; var pathCount = 0
  while heapCount > 0:
    let u = dequeue(heap, heapCount, nodes)
    nodes[u].state = 2
    if total(nodes, u) == total(nodes, goal):
      var q = goal
      while q >= 0 and pathCount < MaxNodes: path[pathCount] = q; inc pathCount; q = nodes[q].parent
      break
    for e in 0..<m:
      if input[edge+2*e] != int64(u): continue
      let v = int(input[edge+2*e+1])
      if not nodes[v].traversable or nodes[v].state == 2: continue
      if nodes[v].state == 0:
        nodes[v].parent = u
        nodes[v].current = nodes[u].current + distance(nodes, u, v) * nodes[v].multiplier
        nodes[v].estimated = nodes[v].current + distance(nodes, v, goal)
        nodes[v].state = 1
        enqueue(heap, heapCount, v, nodes)
      elif total(nodes, u) != total(nodes, v):
        let newCurrent = nodes[u].current + distance(nodes, u, v)
        let newTotal = newCurrent + nodes[u].estimated
        if newTotal < total(nodes, v): nodes[v].parent = u; nodes[v].current = newCurrent
      else: return -1
  let bytes = pathCount * 8
  if bytes == 0: return 0
  if output.isNil or capacity < csize_t(bytes): return -2
  for i in 0..<pathCount: putI64Le(output, i*8, int64(path[pathCount-1-i]))
  int64(bytes)
