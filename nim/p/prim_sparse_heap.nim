const
  MaxVertices = 64
  MaxEdges = 4096
  MaxArcs = 2 * MaxEdges
  NoneVertex = MaxVertices
  NoArc = MaxArcs

proc before(best: array[MaxVertices, int64], left, right: int): bool =
  best[left] < best[right] or (best[left] == best[right] and left < right)

proc exchange(heap: var array[MaxVertices, int], position: var array[MaxVertices, int], first, second: int) =
  swap(heap[first], heap[second])
  position[heap[first]] = first
  position[heap[second]] = second

proc siftUp(heap: var array[MaxVertices, int], position: var array[MaxVertices, int],
            best: array[MaxVertices, int64], start: int) =
  var at = start
  while at > 0:
    let parent = (at - 1) div 2
    if not before(best, heap[at], heap[parent]): break
    exchange(heap, position, at, parent)
    at = parent

proc popMin(heap: var array[MaxVertices, int], position: var array[MaxVertices, int],
            count: var int, best: array[MaxVertices, int64]): int =
  result = heap[0]
  position[result] = NoneVertex
  dec count
  if count > 0:
    heap[0] = heap[count]
    position[heap[0]] = 0
    var at = 0
    while 2 * at + 1 < count:
      var child = 2 * at + 1
      if child + 1 < count and before(best, heap[child + 1], heap[child]): inc child
      if not before(best, heap[child], heap[at]): break
      exchange(heap, position, at, child)
      at = child

proc prim_sparse_heap*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "prim_sparse_heap".} =
  if values == nil or length < 2 or length > csize_t(2 + 3 * MaxEdges): return -2
  if values[0] < 0 or values[0] > MaxVertices or values[1] < 0 or values[1] > MaxEdges: return -2
  let vertices = int(values[0])
  let edgeCount = int(values[1])
  if int(length) != 2 + 3 * edgeCount or (vertices == 0 and edgeCount != 0): return -2
  if vertices == 0: return 0
  for edge in 0 ..< edgeCount:
    let origin = values[2 + 3 * edge]
    let destination = values[3 + 3 * edge]
    let weight = values[4 + 3 * edge]
    if origin < 0 or destination < 0 or origin >= int64(vertices) or destination >= int64(vertices) or
        weight < 0 or weight > 2147483647'i64: return -2

  var head: array[MaxVertices, int]
  var next: array[MaxArcs, int]
  var to: array[MaxArcs, int]
  var arcWeight: array[MaxArcs, int64]
  for vertex in 0 ..< vertices: head[vertex] = NoArc
  var arcCount = 0
  for edge in 0 ..< edgeCount:
    let origin = int(values[2 + 3 * edge])
    let destination = int(values[3 + 3 * edge])
    let weight = values[4 + 3 * edge]
    if origin == destination: continue
    to[arcCount] = destination
    arcWeight[arcCount] = weight
    next[arcCount] = head[origin]
    head[origin] = arcCount
    inc arcCount
    to[arcCount] = origin
    arcWeight[arcCount] = weight
    next[arcCount] = head[destination]
    head[destination] = arcCount
    inc arcCount

  var best: array[MaxVertices, int64]
  var hasBest: array[MaxVertices, bool]
  var selected: array[MaxVertices, bool]
  var heap: array[MaxVertices, int]
  var position: array[MaxVertices, int]
  for vertex in 0 ..< vertices: position[vertex] = NoneVertex
  var heapCount = 1
  var selectedCount = 0
  heap[0] = 0
  position[0] = 0
  hasBest[0] = true
  var total = 0'i64
  while heapCount > 0:
    let origin = popMin(heap, position, heapCount, best)
    selected[origin] = true
    inc selectedCount
    total += best[origin]
    var arc = head[origin]
    while arc != NoArc:
      let destination = to[arc]
      let weight = arcWeight[arc]
      if not selected[destination] and (not hasBest[destination] or weight < best[destination]):
        best[destination] = weight
        hasBest[destination] = true
        if position[destination] == NoneVertex:
          heap[heapCount] = destination
          position[destination] = heapCount
          inc heapCount
        siftUp(heap, position, best, position[destination])
      arc = next[arc]
  if selectedCount == vertices: return total
  -1
