## Clean-room bounded MaxCliqueDyn-style colored branch and bound.
const MaxVertices = 24
const MaxParseableInput = 26

type Candidate = object
  vertex: int
  bound: int

type Search = object
  adjacency: array[MaxVertices, uint64]
  chosen: array[MaxVertices, int]
  chosenCount: int
  best: int
  steps: array[MaxVertices + 2, int]
  priorChildSteps: array[MaxVertices + 2, int]
  totalColorCalls: int

proc degreeOrder(search: Search, vertices: openArray[int]): array[MaxVertices, Candidate] =
  var ids: array[MaxVertices, int]
  var degrees: array[MaxVertices, int]
  var maximumDegree = 0
  for i, vertex in vertices:
    ids[i] = vertex
    for other in vertices:
      if (search.adjacency[vertex] and (1'u64 shl other)) != 0:
        inc degrees[i]
    maximumDegree = max(maximumDegree, degrees[i])
  for i in 1 ..< vertices.len:
    let id = ids[i]
    let degree = degrees[i]
    var j = i
    while j > 0 and (degrees[j - 1] < degree or
        (degrees[j - 1] == degree and ids[j - 1] > id)):
      ids[j] = ids[j - 1]
      degrees[j] = degrees[j - 1]
      dec j
    ids[j] = id
    degrees[j] = degree
  for i in 0 ..< vertices.len:
    result[i] = Candidate(vertex: ids[i], bound: min(i, maximumDegree) + 1)

proc expand(search: var Search, candidates: array[MaxVertices, Candidate],
            candidateCount, level: int) =
  search.steps[level] += search.steps[level - 1] - search.priorChildSteps[level]
  search.priorChildSteps[level] = search.steps[level - 1]
  var count = candidateCount
  while count > 0:
    if search.chosenCount + candidates[count - 1].bound <= search.best: return
    let vertex = candidates[count - 1].vertex
    search.chosen[search.chosenCount] = vertex
    inc search.chosenCount

    var neighbors: array[MaxVertices, int]
    var neighborCount = 0
    for i in 0 ..< count - 1:
      let other = candidates[i].vertex
      if (search.adjacency[vertex] and (1'u64 shl other)) != 0:
        neighbors[neighborCount] = other
        inc neighborCount
    if neighborCount > 0:
      let priorSteps = search.steps[level]
      inc search.steps[level]
      inc search.totalColorCalls
      if priorSteps.int64 * 1000 < search.totalColorCalls.int64 * 25:
        let reordered = degreeOrder(search, neighbors.toOpenArray(0, neighborCount - 1))
        for i in 0 ..< neighborCount:
          neighbors[i] = reordered[i].vertex

      var classMasks: array[MaxVertices, uint64]
      var colors: array[MaxVertices, int]
      var classCount = 0
      for i in 0 ..< neighborCount:
        var color = 0
        while color < classCount and
            (classMasks[color] and search.adjacency[neighbors[i]]) != 0:
          inc color
        if color == classCount: inc classCount
        colors[i] = color + 1
        classMasks[color] = classMasks[color] or (1'u64 shl neighbors[i])

      let minimumColor = max(search.best - search.chosenCount + 1, 1)
      var child: array[MaxVertices, Candidate]
      var childCount = 0
      for color in minimumColor .. classCount:
        for i in 0 ..< neighborCount:
          if colors[i] == color:
            child[childCount] = Candidate(vertex: neighbors[i], bound: color)
            inc childCount
      expand(search, child, childCount, level + 1)
    elif search.chosenCount > search.best:
      search.best = search.chosenCount

    dec search.chosenCount
    dec count

proc konc_maxclique_dyn*(packed: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "konc_maxclique_dyn".} =
  if packed.isNil or length < 1 or length > csize_t(MaxParseableInput): return -1
  let n64 = packed[0]
  if n64 < 0 or n64 > int64(MaxVertices) or int(length) != int(n64) + 1: return -1
  let n = int(n64)
  let domain = (1'u64 shl n) - 1'u64
  var search: Search
  for vertex in 0 ..< n:
    let row = packed[1 + vertex]
    if row < 0 or (uint64(row) and not domain) != 0: return -1
    search.adjacency[vertex] = uint64(row)
    if (search.adjacency[vertex] and (1'u64 shl vertex)) != 0: return -1
  for left in 0 ..< n:
    for right in left + 1 ..< n:
      let forward = (search.adjacency[left] and (1'u64 shl right)) != 0
      let reverse = (search.adjacency[right] and (1'u64 shl left)) != 0
      if forward != reverse: return -1
  if n == 0: return 0
  var vertices: array[MaxVertices, int]
  for vertex in 0 ..< n: vertices[vertex] = vertex
  let roots = degreeOrder(search, vertices.toOpenArray(0, n - 1))
  expand(search, roots, n, 1)
  int64(search.best)
