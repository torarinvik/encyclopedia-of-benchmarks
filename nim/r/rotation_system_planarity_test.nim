# Clean-room bounded rotation-system planarity recognizer.
const MaxN = 6
const MaxM = 15
const MaxDarts = 30

proc rotation_system_planarity_test*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "rotation_system_planarity_test".} =
  if input.isNil or length < csize_t(2) or length > csize_t(33): return -1
  let n64 = input[0]
  let m64 = input[1]
  if n64 < 1 or n64 > MaxN.int64 or m64 < 0 or m64 > MaxM.int64 or int64(length) != 2 + 2 * m64: return -1
  let n = int(n64)
  let m = int(m64)
  var adjacent: array[MaxN * MaxN, bool]
  var edgeU, edgeV: array[MaxM, int]
  for edge in 0 ..< m:
    let u64 = input[2 + 2 * edge]
    let v64 = input[3 + 2 * edge]
    if u64 < 0 or u64 >= v64 or v64 >= n64: return -1
    let u = int(u64)
    let v = int(v64)
    if adjacent[u * MaxN + v]: return -1
    adjacent[u * MaxN + v] = true
    adjacent[v * MaxN + u] = true
    edgeU[edge] = u
    edgeV[edge] = v
  if n >= 3 and m > 3 * n - 6: return 0

  var edgeId: array[MaxN * MaxN, int]
  var neighbors: array[MaxN * MaxN, int]
  var degree: array[MaxN, int]
  for i in 0 ..< MaxN * MaxN: edgeId[i] = -1
  for edge in 0 ..< m:
    edgeId[edgeU[edge] * MaxN + edgeV[edge]] = edge
    edgeId[edgeV[edge] * MaxN + edgeU[edge]] = edge
  for u in 0 ..< n:
    for v in 0 ..< n:
      if adjacent[u * MaxN + v]:
        neighbors[u * MaxN + degree[u]] = v
        inc degree[u]

  var component: array[MaxN, int]
  for v in 0 ..< n: component[v] = -1
  var componentVertices: array[MaxN * MaxN, int]
  var componentSize: array[MaxN, int]
  var componentCount = 0
  for root in 0 ..< n:
    if component[root] == -1:
      let cid = componentCount
      inc componentCount
      var queue: array[MaxN, int]
      var head = 0
      var tail = 0
      component[root] = cid
      queue[tail] = root
      inc tail
      while head < tail:
        let here = queue[head]
        inc head
        componentVertices[cid * MaxN + componentSize[cid]] = here
        inc componentSize[cid]
        for there in 0 ..< n:
          if adjacent[here * MaxN + there] and component[there] == -1:
            component[there] = cid
            queue[tail] = there
            inc tail

  for cid in 0 ..< componentCount:
    var componentEdges = 0
    for edge in 0 ..< m:
      if component[edgeU[edge]] == cid: inc componentEdges
    if componentSize[cid] >= 3 and componentEdges > 3 * componentSize[cid] - 6: return 0
    if componentSize[cid] == 1: continue
    var rotation: array[MaxN * MaxN, int]
    for i in 0 ..< componentSize[cid]:
      let vertex = componentVertices[cid * MaxN + i]
      for j in 0 ..< degree[vertex]: rotation[vertex * MaxN + j] = neighbors[vertex * MaxN + j]
    var found = false
    var done = false
    while not found and not done:
      var successor: array[MaxDarts, int]
      for dart in 0 ..< 2 * m: successor[dart] = -1
      for i in 0 ..< componentSize[cid]:
        let vertex = componentVertices[cid * MaxN + i]
        let d = degree[vertex]
        for j in 0 ..< d:
          let next = (j + 1) mod d
          let edge = edgeId[vertex * MaxN + rotation[vertex * MaxN + j]]
          let nextEdge = edgeId[vertex * MaxN + rotation[vertex * MaxN + next]]
          let dart = 2 * edge + (if edgeU[edge] == vertex: 0 else: 1)
          let nextDart = 2 * nextEdge + (if edgeU[nextEdge] == vertex: 0 else: 1)
          successor[dart] = nextDart
      var used: array[MaxDarts, bool]
      var faces = 0
      for edge in 0 ..< m:
        if component[edgeU[edge]] == cid:
          for orientation in 0 ..< 2:
            var dart = 2 * edge + orientation
            if not used[dart]:
              inc faces
              while not used[dart]:
                used[dart] = true
                dart = successor[dart xor 1]
      if componentSize[cid] - componentEdges + faces == 2:
        found = true
      else:
        var position = componentSize[cid] - 1
        var advanced = false
        while position >= 0 and not advanced:
          let vertex = componentVertices[cid * MaxN + position]
          let d = degree[vertex]
          var pivot = d - 2
          while pivot >= 1 and rotation[vertex * MaxN + pivot] >= rotation[vertex * MaxN + pivot + 1]: dec pivot
          if pivot >= 1:
            var swapAt = d - 1
            while rotation[vertex * MaxN + swapAt] <= rotation[vertex * MaxN + pivot]: dec swapAt
            swap(rotation[vertex * MaxN + pivot], rotation[vertex * MaxN + swapAt])
            var left = pivot + 1
            var right = d - 1
            while left < right:
              swap(rotation[vertex * MaxN + left], rotation[vertex * MaxN + right])
              inc left
              dec right
            advanced = true
          else:
            for j in 0 ..< d: rotation[vertex * MaxN + j] = neighbors[vertex * MaxN + j]
            dec position
        if not advanced: done = true
    if not found: return 0
  1
