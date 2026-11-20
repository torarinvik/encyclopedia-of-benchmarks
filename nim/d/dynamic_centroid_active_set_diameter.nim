import std/ffi

const
  MaxN = 32
  MaxOperations = 64
  MaxLevels = 6
  MaxParseableLength = 98
  MaxValidLength = 97

type
  Adjacency = array[MaxN * MaxN, int]
  Nodes = array[MaxN, int]
  Records = array[MaxN * MaxLevels, int]
  BestBuckets = array[MaxN * (MaxN + 1), int]

proc componentSize(n: int, adjacency: var Adjacency, blocked: var Nodes,
                   subtreeSize: var Nodes, vertex, parent: int): int =
  var total = 1
  for neighbor in 0 ..< n:
    if adjacency[vertex * n + neighbor] != 0 and neighbor != parent and blocked[neighbor] == 0:
      total += componentSize(n, adjacency, blocked, subtreeSize, neighbor, vertex)
  subtreeSize[vertex] = total
  total

proc chooseCentroid(n: int, adjacency: var Adjacency, blocked: var Nodes,
                    subtreeSize: var Nodes, vertex, parent, total: int): int =
  for neighbor in 0 ..< n:
    if adjacency[vertex * n + neighbor] != 0 and neighbor != parent
        and blocked[neighbor] == 0 and subtreeSize[neighbor] > total div 2:
      return chooseCentroid(n, adjacency, blocked, subtreeSize, neighbor, vertex, total)
  vertex

proc recordComponent(n, level: int, adjacency: var Adjacency, blocked: var Nodes,
                     recordCount: var Nodes, recordCentroid, recordBranch,
                     recordDistance: var Records, centroid, vertex, parent,
                     distance, branch: int) =
  if level >= MaxLevels: return
  let index = vertex * MaxLevels + level
  recordCentroid[index] = centroid
  recordBranch[index] = (if vertex == centroid: n else: branch)
  recordDistance[index] = distance
  recordCount[vertex] = level + 1
  for neighbor in 0 ..< n:
    if adjacency[vertex * n + neighbor] != 0 and neighbor != parent and blocked[neighbor] == 0:
      let nextBranch = (if vertex == centroid: neighbor else: branch)
      recordComponent(n, level, adjacency, blocked, recordCount, recordCentroid,
                      recordBranch, recordDistance, centroid, neighbor, vertex,
                      distance + 1, nextBranch)

proc buildCentroidRecords(n, level: int, adjacency: var Adjacency,
                          blocked, subtreeSize: var Nodes, recordCount: var Nodes,
                          recordCentroid, recordBranch, recordDistance: var Records,
                          entry: int) =
  if level >= MaxLevels: return
  let total = componentSize(n, adjacency, blocked, subtreeSize, entry, -1)
  let centroid = chooseCentroid(n, adjacency, blocked, subtreeSize, entry, -1, total)
  recordComponent(n, level, adjacency, blocked, recordCount, recordCentroid,
                  recordBranch, recordDistance, centroid, centroid, -1, 0, n)
  blocked[centroid] = 1
  for neighbor in 0 ..< n:
    if adjacency[centroid * n + neighbor] != 0 and blocked[neighbor] == 0:
      buildCentroidRecords(n, level + 1, adjacency, blocked, subtreeSize,
                           recordCount, recordCentroid, recordBranch,
                           recordDistance, neighbor)

proc recomputeBranch(n: int, active: var Nodes, recordCount: var Nodes,
                     recordCentroid, recordBranch, recordDistance: var Records,
                     best: var BestBuckets, centroid, branch: int) =
  best[centroid * (n + 1) + branch] = -1
  for vertex in 0 ..< n:
    if active[vertex] != 0:
      for record in 0 ..< recordCount[vertex]:
        let index = vertex * MaxLevels + record
        if recordCentroid[index] == centroid and recordBranch[index] == branch
            and recordDistance[index] > best[centroid * (n + 1) + branch]:
          best[centroid * (n + 1) + branch] = recordDistance[index]

proc activeDiameter(n: int, best: var BestBuckets): int =
  var answer = 0
  for centroid in 0 ..< n:
    var first = -1
    var second = -1
    for branch in 0 .. n:
      let distance = best[centroid * (n + 1) + branch]
      if distance > first:
        second = first
        first = distance
      elif distance > second:
        second = distance
    if second >= 0 and first + second > answer:
      answer = first + second
  answer

proc dynamic_centroid_active_set_diameter*(input: ptr UncheckedArray[int64],
                                           length: csize_t): int64
    {.cdecl, exportc: "dynamic_centroid_active_set_diameter".} =
  if input.isNil or length < 2 or length > csize_t(MaxParseableLength): return -1
  let nValue = input[0]
  let operationCountValue = input[1]
  if nValue < 1 or nValue > int64(MaxN)
      or operationCountValue < 0 or operationCountValue > int64(MaxOperations): return -1
  let n = int(nValue)
  let operationCount = int(operationCountValue)
  if length != csize_t(n + 1 + operationCount): return -1

  var adjacency: Adjacency
  var blocked, subtreeSize, recordCount, active: Nodes
  var recordCentroid, recordBranch, recordDistance: Records
  var best: BestBuckets
  for vertex in 1 ..< n:
    let parentValue = input[vertex + 1]
    if parentValue < 0 or parentValue >= int64(vertex): return -1
    let parent = int(parentValue)
    adjacency[parent * n + vertex] = 1
    adjacency[vertex * n + parent] = 1
  for offset in 0 ..< operationCount:
    let operation = input[n + 1 + offset]
    if operation != -1 and (operation < 0 or operation >= int64(n)): return -1

  buildCentroidRecords(n, 0, adjacency, blocked, subtreeSize, recordCount,
                       recordCentroid, recordBranch, recordDistance, 0)
  for centroid in 0 ..< n:
    for branch in 0 .. n:
      best[centroid * (n + 1) + branch] = -1

  var checksum = 0'i64
  var queryNumber = 0'i64
  for offset in 0 ..< operationCount:
    let operation = input[n + 1 + offset]
    if operation == -1:
      inc queryNumber
      checksum += queryNumber * int64(activeDiameter(n, best) + 1)
    else:
      let vertex = int(operation)
      active[vertex] = if active[vertex] == 0: 1 else: 0
      for record in 0 ..< recordCount[vertex]:
        let index = vertex * MaxLevels + record
        let centroid = recordCentroid[index]
        let branch = recordBranch[index]
        let distance = recordDistance[index]
        let bucket = centroid * (n + 1) + branch
        if active[vertex] != 0:
          if distance > best[bucket]: best[bucket] = distance
        elif best[bucket] == distance:
          recomputeBranch(n, active, recordCount, recordCentroid, recordBranch,
                          recordDistance, best, centroid, branch)
  checksum
