const
  MaxVertices = 16
  MaxEdges = 48
  MaxEvents = 16
  MaxParseableInputLength = 199
  Infinity = 1_000_000_000'i64

type Key = tuple[first, second: int64]

proc manhattan(left, right, width: int): int64 =
  let leftRow = left div width
  let rightRow = right div width
  let leftColumn = left mod width
  let rightColumn = right mod width
  int64(abs(leftRow - rightRow) + abs(leftColumn - rightColumn))

proc calculateKey(vertex, start, width: int; km: int64;
                  g, rhs: array[MaxVertices, int64]): Key =
  let minimum = min(g[vertex], rhs[vertex])
  (minimum + manhattan(start, vertex, width) + km, minimum)

proc keyLess(left, right: Key): bool =
  left.first < right.first or (left.first == right.first and left.second < right.second)

proc updateVertex(vertex, goal, start, width, edgeCount: int; km: int64;
                  tails, heads: array[MaxEdges, int]; costs: array[MaxEdges, int64];
                  g: array[MaxVertices, int64]; rhs: var array[MaxVertices, int64];
                  inOpen: var array[MaxVertices, bool];
                  keyFirst, keySecond: var array[MaxVertices, int64]) =
  if vertex != goal:
    var best = Infinity
    for edge in 0 ..< edgeCount:
      if tails[edge] == vertex:
        let candidate = costs[edge] + g[heads[edge]]
        if candidate < best:
          best = candidate
    rhs[vertex] = best

  inOpen[vertex] = false
  if g[vertex] != rhs[vertex]:
    let key = calculateKey(vertex, start, width, km, g, rhs)
    inOpen[vertex] = true
    keyFirst[vertex] = key.first
    keySecond[vertex] = key.second

proc computeShortestPath(start, goal, width, vertexCount, edgeCount: int; km: int64;
                         tails, heads: array[MaxEdges, int]; costs: array[MaxEdges, int64];
                         g: var array[MaxVertices, int64]; rhs: var array[MaxVertices, int64];
                         inOpen: var array[MaxVertices, bool];
                         keyFirst, keySecond: var array[MaxVertices, int64]) =
  while true:
    var top = MaxVertices
    var topKey: Key = (0'i64, 0'i64)
    for vertex in 0 ..< vertexCount:
      if inOpen[vertex]:
        let key: Key = (keyFirst[vertex], keySecond[vertex])
        if top == MaxVertices or keyLess(key, topKey) or
            (key.first == topKey.first and key.second == topKey.second and vertex < top):
          top = vertex
          topKey = key

    let startKey = calculateKey(start, start, width, km, g, rhs)
    if top == MaxVertices or
        (not keyLess(topKey, startKey) and rhs[start] == g[start]):
      break

    let oldKey = topKey
    let newKey = calculateKey(top, start, width, km, g, rhs)
    if keyLess(oldKey, newKey):
      keyFirst[top] = newKey.first
      keySecond[top] = newKey.second
      continue

    inOpen[top] = false
    if g[top] > rhs[top]:
      g[top] = rhs[top]
      for edge in 0 ..< edgeCount:
        if heads[edge] == top:
          updateVertex(tails[edge], goal, start, width, edgeCount, km,
                       tails, heads, costs, g, rhs, inOpen, keyFirst, keySecond)
    else:
      g[top] = Infinity
      updateVertex(top, goal, start, width, edgeCount, km,
                   tails, heads, costs, g, rhs, inOpen, keyFirst, keySecond)
      for edge in 0 ..< edgeCount:
        if heads[edge] == top:
          updateVertex(tails[edge], goal, start, width, edgeCount, km,
                       tails, heads, costs, g, rhs, inOpen, keyFirst, keySecond)

proc d_star_lite_incremental_replanning*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "d_star_lite_incremental_replanning".} =
  if input == nil or length < csize_t(6) or length > csize_t(MaxParseableInputLength):
    return -1

  let heightValue = input[0]
  let widthValue = input[1]
  let edgeCountValue = input[2]
  let eventCountValue = input[3]
  if heightValue < 1 or heightValue > 4 or widthValue < 1 or widthValue > 4 or
      edgeCountValue < 0 or eventCountValue < 0 or eventCountValue > int64(MaxEvents):
    return -1
  let height = int(heightValue)
  let width = int(widthValue)
  let vertexCount = height * width
  if vertexCount < 2:
    return -1
  let maximumEdges = 2 * (height * (width - 1) + width * (height - 1))
  if edgeCountValue > int64(maximumEdges) or edgeCountValue > int64(MaxEdges):
    return -1
  let edgeCount = int(edgeCountValue)
  let eventCount = int(eventCountValue)
  let startValue = input[4]
  let goalValue = input[5]
  if startValue < 0 or startValue >= int64(vertexCount) or
      goalValue < 0 or goalValue >= int64(vertexCount):
    return -1
  if length != csize_t(6 + 3 * edgeCount + 3 * eventCount):
    return -1

  var tails, heads: array[MaxEdges, int]
  var costs: array[MaxEdges, int64]
  for edge in 0 ..< edgeCount:
    let offset = 6 + 3 * edge
    let tailValue = input[offset]
    let headValue = input[offset + 1]
    let cost = input[offset + 2]
    if tailValue < 0 or tailValue >= int64(vertexCount) or
        headValue < 0 or headValue >= int64(vertexCount) or cost < 1 or cost > 9:
      return -1
    let tail = int(tailValue)
    let head = int(headValue)
    if manhattan(tail, head, width) != 1:
      return -1
    for previous in 0 ..< edge:
      if tails[previous] == tail and heads[previous] == head:
        return -1
    tails[edge] = tail
    heads[edge] = head
    costs[edge] = cost

  var eventStarts: array[MaxEvents, int]
  var eventEdges: array[MaxEvents, int]
  var eventCosts: array[MaxEvents, int64]
  for event in 0 ..< eventCount:
    let offset = 6 + 3 * edgeCount + 3 * event
    let newStart = input[offset]
    let edgeId = input[offset + 1]
    let newCost = input[offset + 2]
    if newStart < 0 or newStart >= int64(vertexCount) or
        edgeId < 0 or edgeId >= int64(edgeCount) or newCost < 1 or newCost > 9:
      return -1
    eventStarts[event] = int(newStart)
    eventEdges[event] = int(edgeId)
    eventCosts[event] = newCost

  var g, rhs: array[MaxVertices, int64]
  var inOpen: array[MaxVertices, bool]
  var keyFirst, keySecond: array[MaxVertices, int64]
  for vertex in 0 ..< vertexCount:
    g[vertex] = Infinity
    rhs[vertex] = Infinity
  let initialStart = int(startValue)
  let goal = int(goalValue)
  var currentStart = initialStart
  var lastStart = initialStart
  var km = 0'i64
  rhs[goal] = 0
  updateVertex(goal, goal, currentStart, width, edgeCount, km,
               tails, heads, costs, g, rhs, inOpen, keyFirst, keySecond)

  var checksum = 0'i64
  for event in 0 ..< eventCount:
    let newStart = eventStarts[event]
    km += manhattan(lastStart, newStart, width)
    lastStart = newStart
    currentStart = newStart
    costs[eventEdges[event]] = eventCosts[event]
    updateVertex(tails[eventEdges[event]], goal, currentStart, width, edgeCount, km,
                 tails, heads, costs, g, rhs, inOpen, keyFirst, keySecond)
    computeShortestPath(currentStart, goal, width, vertexCount, edgeCount, km,
                        tails, heads, costs, g, rhs, inOpen, keyFirst, keySecond)

    var distanceCode = 136'i64
    var nextCode = 0'i64
    if g[currentStart] < Infinity:
      distanceCode = g[currentStart]
      if currentStart != goal:
        var nextVertex = MaxVertices
        for edge in 0 ..< edgeCount:
          if tails[edge] == currentStart and costs[edge] + g[heads[edge]] == g[currentStart] and
              heads[edge] < nextVertex:
            nextVertex = heads[edge]
        if nextVertex < MaxVertices:
          nextCode = int64(nextVertex + 1)
    checksum += int64(event + 1) * (distanceCode + 1) * (nextCode + 1)
  checksum
