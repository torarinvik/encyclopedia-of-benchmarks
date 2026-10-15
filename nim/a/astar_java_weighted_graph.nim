const MaxVertices = 7
const MaxStates = 4096

type SearchState = object
  distance: int32
  heuristic: int32
  pathLength: int
  path: array[MaxVertices, int32]

proc writeI64(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byteIndex in 0 ..< 8:
    output[offset + byteIndex] = uint8((bits shr (byteIndex * 8)) and 255)

proc astar_java_weighted_graph*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64 {.cdecl, exportc: "astar_java_weighted_graph".} =
  if input.isNil or length < 5: return -1
  let n64 = input[0]
  let m64 = input[1]
  let start64 = input[2]
  let target64 = input[3]
  if n64 < 1 or n64 > MaxVertices or m64 < 0 or m64 > 16 or
      start64 < 0 or start64 >= n64 or target64 < 0 or target64 >= n64 or
      length != csize_t(4 + n64 + 3 * m64): return -1
  let n = int(n64)
  let m = int(m64)
  let start = int(start64)
  let target = int(target64)
  var heuristic: array[MaxVertices, int32]
  var adjacent: array[MaxVertices, array[MaxVertices, int32]]
  var weights: array[MaxVertices, array[MaxVertices, int32]]
  var degree: array[MaxVertices, int]
  for i in 0 ..< n:
    if input[4 + i] < -1000 or input[4 + i] > 1000: return -1
    heuristic[i] = int32(input[4 + i])
  var position = 4 + n
  for _ in 0 ..< m:
    let u64 = input[position]
    let v64 = input[position + 1]
    let weight64 = input[position + 2]
    position += 3
    if u64 < 0 or u64 >= n64 or v64 < 0 or v64 >= n64 or u64 == v64 or weight64 < 0 or weight64 > 1000:
      return -1
    let u = int(u64)
    let v = int(v64)
    for i in 0 ..< degree[u]:
      if adjacent[u][i] == int32(v): return -1
    adjacent[u][degree[u]] = int32(v)
    weights[u][degree[u]] = int32(weight64)
    inc degree[u]
    adjacent[v][degree[v]] = int32(u)
    weights[v][degree[v]] = int32(weight64)
    inc degree[v]
  var states: array[MaxStates, SearchState]
  var heap: array[MaxStates, int]
  var stateCount = 1
  var heapSize = 1
  states[0].distance = 0
  states[0].heuristic = heuristic[start]
  states[0].pathLength = 1
  states[0].path[0] = int32(start)
  heap[0] = 0
  var found = false
  var solution = 0
  while heapSize > 0:
    let currentIndex = heap[0]
    let last = heap[heapSize - 1]
    dec heapSize
    if heapSize > 0:
      var i = 0
      let half = heapSize div 2
      while i < half:
        var child = 2 * i + 1
        var childIndex = heap[child]
        let right = child + 1
        if right < heapSize and
            states[heap[right]].distance + states[heap[right]].heuristic <
            states[childIndex].distance + states[childIndex].heuristic:
          child = right
          childIndex = heap[right]
        if states[last].distance + states[last].heuristic <=
            states[childIndex].distance + states[childIndex].heuristic: break
        heap[i] = childIndex
        i = child
      heap[i] = last
    let current = states[currentIndex]
    let currentVertex = int(current.path[current.pathLength - 1])
    if currentVertex == target:
      found = true
      solution = currentIndex
      break
    for edge in 0 ..< degree[currentVertex]:
      let next = adjacent[currentVertex][edge]
      var inPath = false
      for i in 0 ..< current.pathLength:
        if current.path[i] == next:
          inPath = true
          break
      if inPath: continue
      if stateCount >= MaxStates or heapSize >= MaxStates: return -1
      let nextState = stateCount
      inc stateCount
      states[nextState].distance = current.distance + weights[currentVertex][edge]
      states[nextState].heuristic = heuristic[int(next)]
      states[nextState].pathLength = current.pathLength + 1
      for i in 0 ..< current.pathLength: states[nextState].path[i] = current.path[i]
      states[nextState].path[current.pathLength] = next
      var i = heapSize
      inc heapSize
      while i > 0:
        let parent = (i - 1) div 2
        let parentIndex = heap[parent]
        if states[parentIndex].distance + states[parentIndex].heuristic <=
            states[nextState].distance + states[nextState].heuristic: break
        heap[i] = parentIndex
        i = parent
      heap[i] = nextState
  var result: array[3 + MaxVertices, int64]
  var resultWords = 3
  if not found:
    result[0] = -1
    result[1] = -1
    result[2] = 0
  else:
    let state = states[solution]
    result[0] = int64(state.distance)
    result[1] = int64(state.heuristic)
    result[2] = int64(state.pathLength)
    resultWords += state.pathLength
    for i in 0 ..< state.pathLength: result[3 + i] = int64(state.path[i])
  let outputBytes = resultWords * 8
  if output.isNil or capacity < csize_t(outputBytes): return -2
  for i in 0 ..< resultWords: writeI64(output, i * 8, result[i])
  int64(outputBytes)
