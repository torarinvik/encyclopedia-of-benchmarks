import std/options

const MaxN = 8
const MaxInput = 49
const MaxDarts = 48

type
  Embedding = object
    n, u, v, w: int
    degree: array[MaxN, int]
    rotation: array[MaxN, array[MaxN, int]]
    adjacent: array[MaxN, array[MaxN, bool]]

proc nextActive(g: Embedding, active: array[MaxN, bool], source, target: int): int =
  var sourcePosition = -1
  var remaining = 0
  for index in 0 ..< g.degree[target]:
    let neighbor = g.rotation[target][index]
    if active[neighbor]:
      inc remaining
      if neighbor == source: sourcePosition = index
  if remaining < 2 or sourcePosition < 0: return -1
  for step in 1 .. g.degree[target]:
    let neighbor = g.rotation[target][(sourcePosition + step) mod g.degree[target]]
    if active[neighbor]: return neighbor
  -1

proc faceCycle(g: Embedding, active: array[MaxN, bool], first, second: int,
    cycle: var array[MaxDarts, int]): int =
  var seen: array[MaxN, array[MaxN, bool]]
  var source = first
  var target = second
  var length = 0
  for _ in 0 ..< MaxDarts:
    if source < 0 or source >= g.n or target < 0 or target >= g.n or
        not active[source] or not active[target] or not g.adjacent[source][target] or seen[source][target]: return -1
    seen[source][target] = true
    cycle[length] = source
    inc length
    let following = nextActive(g, active, source, target)
    if following < 0: return -1
    source = target
    target = following
    if source == first and target == second: return length
  -1

proc parseEmbedding(input: ptr UncheckedArray[int64], length: int): Option[Embedding] =
  if length < 4 or length > MaxInput: return none(Embedding)
  if input[0] < 3 or input[0] > MaxN.int64: return none(Embedding)
  let n = int(input[0])
  if input[1] < 0 or input[1] >= input[0] or input[2] < 0 or input[2] >= input[0] or
      input[3] < 0 or input[3] >= input[0] or input[1] == input[2] or input[1] == input[3] or input[2] == input[3]:
    return none(Embedding)
  var g = Embedding(n: n, u: int(input[1]), v: int(input[2]), w: int(input[3]))
  var offset = 4
  var degreeSum = 0
  for vertex in 0 ..< n:
    if offset >= length: return none(Embedding)
    let degreeRaw = input[offset]
    inc offset
    if degreeRaw < 2 or degreeRaw >= input[0] or offset + int(degreeRaw) > length: return none(Embedding)
    let degree = int(degreeRaw)
    g.degree[vertex] = degree
    degreeSum += degree
    var rowSeen: array[MaxN, bool]
    for rank in 0 ..< degree:
      let raw = input[offset]
      inc offset
      if raw < 0 or raw >= input[0] or raw == vertex.int64: return none(Embedding)
      let neighbor = int(raw)
      if rowSeen[neighbor]: return none(Embedding)
      rowSeen[neighbor] = true
      g.rotation[vertex][rank] = neighbor
      g.adjacent[vertex][neighbor] = true
  if offset != length or degreeSum != 6 * n - 12: return none(Embedding)
  var edgeCount = 0
  for a in 0 ..< n:
    for b in 0 ..< n:
      if g.adjacent[a][b] != g.adjacent[b][a]: return none(Embedding)
      if a < b and g.adjacent[a][b]: inc edgeCount
  if edgeCount != 3 * n - 6: return none(Embedding)
  var reached: array[MaxN, bool]
  var stack: array[MaxN, int]
  var top = 1
  var reachedCount = 0
  reached[0] = true
  while top > 0:
    dec top
    let vertex = stack[top]
    inc reachedCount
    for neighbor in 0 ..< n:
      if g.adjacent[vertex][neighbor] and not reached[neighbor]:
        reached[neighbor] = true
        stack[top] = neighbor
        inc top
  if reachedCount != n: return none(Embedding)
  var allActive: array[MaxN, bool]
  for i in 0 ..< n: allActive[i] = true
  var seenDart: array[MaxN, array[MaxN, bool]]
  var faceCount = 0
  var visitedDarts = 0
  for source in 0 ..< n:
    for target in 0 ..< n:
      if not g.adjacent[source][target] or seenDart[source][target]: continue
      var cycle: array[MaxDarts, int]
      let faceLength = faceCycle(g, allActive, source, target, cycle)
      if faceLength != 3: return none(Embedding)
      inc faceCount
      for i in 0 ..< faceLength:
        let a = cycle[i]
        let b = cycle[(i + 1) mod faceLength]
        if seenDart[a][b]: return none(Embedding)
        seenDart[a][b] = true
        inc visitedDarts
  if faceCount != 2 * n - 4 or visitedDarts != 6 * n - 12: return none(Embedding)
  var outer: array[MaxDarts, int]
  let outerLength = faceCycle(g, allActive, g.u, g.v, outer)
  if outerLength != 3 or outer[0] != g.u or outer[1] != g.v or outer[2] != g.w: return none(Embedding)
  some(g)

proc boundaryPath(g: Embedding, active: array[MaxN, bool], path: var array[MaxN, int]): int =
  var cycle: array[MaxDarts, int]
  let length = faceCycle(g, active, g.u, g.v, cycle)
  if length < 3: return -1
  var count = 1
  path[0] = g.u
  var index = length - 1
  while index >= 2:
    path[count] = cycle[index]
    inc count
    dec index
  path[count] = g.v
  count + 1

proc peelChoice(g: Embedding, path: array[MaxN, int], length: int): int =
  var chord: array[MaxN, array[MaxN, bool]]
  var chordCount = 0
  for left in 0 ..< length:
    for right in left + 2 ..< length:
      if left == 0 and right == length - 1: continue
      if g.adjacent[path[left]][path[right]]:
        chord[left][right] = true
        inc chordCount
  var eligible: array[MaxN, bool]
  if chordCount == 0:
    for i in 1 ..< length - 1: eligible[path[i]] = true
  else:
    for left in 0 ..< length:
      for right in left + 2 ..< length:
        if not chord[left][right]: continue
        var minimal = true
        for a in left ..< right:
          for b in a + 2 .. right:
            if chord[a][b] and (a != left or b != right): minimal = false
        if minimal:
          for i in left + 1 ..< right: eligible[path[i]] = true
  for vertex in 0 ..< g.n:
    if eligible[vertex]: return vertex
  -1

proc storeI64Le(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8: output[offset + byte] = uint8((bits shr (8 * byte)) and 255'u64)

proc canonical_order_maximal_plane_triangulation*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "canonical_order_maximal_plane_triangulation".} =
  if input == nil or length < csize_t(4) or length > csize_t(MaxInput): return -1
  let parsed = parseEmbedding(input, int(length))
  if parsed.isNone: return -1
  let g = parsed.get
  var active: array[MaxN, bool]
  for i in 0 ..< g.n: active[i] = true
  var removals: array[MaxN, int]
  var removed = 0
  if g.n > 3:
    active[g.w] = false
    removals[removed] = g.w
    inc removed
    var path: array[MaxN, int]
    var pathLength = boundaryPath(g, active, path)
    if pathLength < 3: return -1
    var activeCount = g.n - 1
    while activeCount > 3:
      let choice = peelChoice(g, path, pathLength)
      if choice < 0 or choice == g.u or choice == g.v or not active[choice]: return -1
      active[choice] = false
      removals[removed] = choice
      inc removed
      dec activeCount
      pathLength = boundaryPath(g, active, path)
      if pathLength < 3: return -1
    if pathLength != 3 or path[0] != g.u or path[2] != g.v: return -1
  var words: array[MaxN + 1, int64]
  words[0] = g.n.int64
  words[1] = g.u.int64
  words[2] = g.v.int64
  var count = 3
  if g.n == 3:
    words[count] = g.w.int64
    inc count
  else:
    var third = -1
    for node in 0 ..< g.n:
      if active[node] and node != g.u and node != g.v: third = node
    if third < 0: return -1
    words[count] = third.int64
    inc count
    var index = removed - 1
    while index >= 0:
      words[count] = removals[index].int64
      inc count
      dec index
  if count != g.n + 1 or words[count - 1] != g.w.int64: return -1
  let required = csize_t(8 * count)
  if output == nil or capacity < required: return -2
  for index in 0 ..< count: storeI64Le(output, 8 * index, words[index])
  int64(required)
