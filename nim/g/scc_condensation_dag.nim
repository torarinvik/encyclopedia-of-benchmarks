# Clean-room bounded Kosaraju plus condensation quotient construction.
import std/posix

const MaxN = 8
const MaxM = 28
const MaxInput = 58
const MaxOutput = 17

proc scc_condensation_dag*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "scc_condensation_dag".} =
  if input.isNil or length < csize_t(2) or length > csize_t(MaxInput): return -1
  let n64 = input[0]
  let m64 = input[1]
  if n64 < 0 or n64 > MaxN.int64 or m64 < 0 or m64 > MaxM.int64: return -1
  let n = int(n64)
  let m = int(m64)
  if int64(length) != 2 + 2 * m64: return -1
  var adjacency: array[MaxN, uint16]
  var reverse: array[MaxN, uint16]
  for edge in 0..<m:
    let source = input[2 + 2 * edge]
    let target = input[3 + 2 * edge]
    if source < 0 or source >= n64 or target < 0 or target >= n64: return -1
    adjacency[int(source)] = adjacency[int(source)] or (uint16(1) shl int(target))
    reverse[int(target)] = reverse[int(target)] or (uint16(1) shl int(source))

  var visited: array[MaxN, bool]
  var order: array[MaxN, int]
  var stackVertex: array[MaxN, int]
  var stackNext: array[MaxN, int]
  var orderCount = 0
  for start in 0..<n:
    if visited[start]: continue
    var stackSize = 1
    stackVertex[0] = start
    stackNext[0] = 0
    visited[start] = true
    while stackSize > 0:
      let frame = stackSize - 1
      let vertex = stackVertex[frame]
      var candidate = stackNext[frame]
      while candidate < n and (adjacency[vertex] and (uint16(1) shl candidate)) == 0: inc candidate
      if candidate < n:
        stackNext[frame] = candidate + 1
        if not visited[candidate]:
          visited[candidate] = true
          stackVertex[stackSize] = candidate
          stackNext[stackSize] = 0
          inc stackSize
      else:
        order[orderCount] = vertex
        inc orderCount
        dec stackSize

  var rawComponent: array[MaxN, int]
  for vertex in 0..<n:
    rawComponent[vertex] = -1
    visited[vertex] = false
  var componentCount = 0
  while orderCount > 0:
    dec orderCount
    let start = order[orderCount]
    if visited[start]: continue
    var stackSize = 1
    stackVertex[0] = start
    visited[start] = true
    rawComponent[start] = componentCount
    while stackSize > 0:
      dec stackSize
      let vertex = stackVertex[stackSize]
      for next in 0..<n:
        if (reverse[vertex] and (uint16(1) shl next)) != 0 and not visited[next]:
          visited[next] = true
          rawComponent[next] = componentCount
          stackVertex[stackSize] = next
          inc stackSize
    inc componentCount

  var minimum: array[MaxN, int]
  var rawOrder: array[MaxN, int]
  var canonical: array[MaxN, int]
  var labels: array[MaxN, int]
  var rowMask: array[MaxN, uint8]
  for component in 0..<componentCount:
    minimum[component] = n
    rawOrder[component] = component
  for vertex in 0..<n:
    let component = rawComponent[vertex]
    if vertex < minimum[component]: minimum[component] = vertex
  for i in 1..<componentCount:
    let key = rawOrder[i]
    var j = i
    while j > 0 and minimum[rawOrder[j - 1]] > minimum[key]:
      rawOrder[j] = rawOrder[j - 1]
      dec j
    rawOrder[j] = key
  for i in 0..<componentCount: canonical[rawOrder[i]] = i
  for vertex in 0..<n: labels[vertex] = canonical[rawComponent[vertex]]
  for source in 0..<n:
    for target in 0..<n:
      if (adjacency[source] and (uint16(1) shl target)) == 0: continue
      let left = labels[source]
      let right = labels[target]
      if left != right: rowMask[left] = rowMask[left] or (uint8(1) shl right)

  let outputSize = 1 + n + componentCount
  if output.isNil or capacity < csize_t(outputSize): return -2
  var staged: array[MaxOutput, uint8]
  staged[0] = uint8(componentCount)
  for vertex in 0..<n: staged[1 + vertex] = uint8(labels[vertex])
  for component in 0..<componentCount: staged[1 + n + component] = rowMask[component]
  for index in 0..<outputSize: output[index] = staged[index]
  int64(outputSize)
