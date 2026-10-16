const MaxVertices = 8
const MaxInputLength = 58

proc hasCycle(n: int, graph: array[MaxVertices * MaxVertices, uint8], visited: var array[MaxVertices, bool], current, position: int): bool =
  if position == n: return graph[current * MaxVertices] != 0
  for next in 0 ..< n:
    if graph[current * MaxVertices + next] != 0 and not visited[next]:
      visited[next] = true
      if hasCycle(n, graph, visited, next, position + 1): return true
      visited[next] = false
  false

proc hamiltonian_cycle_exists*(input: ptr UncheckedArray[int64], length: csize_t): int64 {.cdecl, exportc: "hamiltonian_cycle_exists".} =
  if input.isNil or length < 2 or length > MaxInputLength: return -1
  let nValue = input[0]
  let mValue = input[1]
  if nValue < 3 or nValue > MaxVertices or mValue < 0: return -1
  let n = int(nValue)
  if mValue > int64(n * (n - 1) div 2): return -1
  let m = int(mValue)
  if int(length) != 2 + 2 * m: return -1
  var graph: array[MaxVertices * MaxVertices, uint8]
  for edge in 0 ..< m:
    let uValue = input[2 + 2 * edge]
    let vValue = input[3 + 2 * edge]
    if uValue < 0 or vValue < 0 or uValue >= nValue or vValue >= nValue or uValue == vValue: return -1
    let u = int(uValue)
    let v = int(vValue)
    if graph[u * MaxVertices + v] != 0: return -1
    graph[u * MaxVertices + v] = 1
    graph[v * MaxVertices + u] = 1
  var visited: array[MaxVertices, bool]
  visited[0] = true
  if hasCycle(n, graph, visited, 0, 1): 1 else: 0
