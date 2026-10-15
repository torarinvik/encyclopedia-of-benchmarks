const MaxNodeCount = 1023
const InvalidResult = -1'i64

proc lowest_common_ancestor*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "lowest_common_ancestor".} =
  if input.isNil or length < 4 or input[0] < 2 or input[0] > MaxNodeCount:
    return InvalidResult
  let count = int(input[0])
  if int(length) != 4 + 3 * count: return InvalidResult
  for field in 1 .. 3:
    if input[field] < 0 or input[field] >= int64(count): return InvalidResult
  if input[2] == input[3]: return InvalidResult
  let root = int(input[1])
  let p = int(input[2])
  let q = int(input[3])

  var parent: array[MaxNodeCount, int64]
  var stack: array[MaxNodeCount, int]
  var pathP: array[MaxNodeCount, int]
  var pathQ: array[MaxNodeCount, int]
  var seen: array[MaxNodeCount, bool]
  for node in 0 ..< count: parent[node] = -1
  for node in 0 ..< count:
    let offset = 4 + 3 * node
    if input[offset] < -1_000_000_000 or input[offset] > 1_000_000_000: return InvalidResult
    for edge in 1 .. 2:
      let child = input[offset + edge]
      if child < -1 or child >= int64(count): return InvalidResult
      if child >= 0:
        let childIndex = int(child)
        if parent[childIndex] != -1: return InvalidResult
        parent[childIndex] = int64(node)
  if parent[root] != -1: return InvalidResult
  for node in 0 ..< count:
    if node != root and parent[node] == -1: return InvalidResult

  var top = 0
  var reached = 0
  stack[top] = root
  inc top
  while top > 0:
    dec top
    let node = stack[top]
    if seen[node]: return InvalidResult
    seen[node] = true
    inc reached
    let offset = 4 + 3 * node
    for edge in 1 .. 2:
      let child = input[offset + edge]
      if child >= 0:
        stack[top] = int(child)
        inc top
  if reached != count: return InvalidResult

  var depthP = 0
  var depthQ = 0
  var current = p
  pathP[depthP] = current
  inc depthP
  while current != root:
    current = int(parent[current])
    pathP[depthP] = current
    inc depthP
  current = q
  pathQ[depthQ] = current
  inc depthQ
  while current != root:
    current = int(parent[current])
    pathQ[depthQ] = current
    inc depthQ

  var ancestor = InvalidResult
  while depthP > 0 and depthQ > 0 and pathP[depthP - 1] == pathQ[depthQ - 1]:
    ancestor = int64(pathP[depthP - 1])
    dec depthP
    dec depthQ
  ancestor
