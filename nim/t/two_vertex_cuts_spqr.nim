const
  MaxN = 8
  MaxM = 28
  MaxInput = 67
  MaxPieces = 56
  MaxSplits = 28
  Modulus = 998244353'i64
  KindS = 1
  KindP = 2
  KindR = 3

type
  EdgeRef = object
    u, v, pairId: int
    real: bool
  Piece = object
    edgeCount: int
    edges: array[MaxM, EdgeRef]

proc connectedWithout(adjacency: array[MaxN * MaxN, bool], n, removed: int): bool =
  var start = 0
  while start == removed: inc start
  var seen: array[MaxN, bool]
  var queue: array[MaxN, int]
  var head = 0
  var tail = 1
  seen[start] = true
  queue[0] = start
  while head < tail:
    let u = queue[head]
    inc head
    for v in 0 ..< n:
      if v != removed and adjacency[u * MaxN + v] and not seen[v]:
        seen[v] = true
        queue[tail] = v
        inc tail
  var reached = 0
  for v in 0 ..< n:
    if v != removed and seen[v]: inc reached
  reached == n - (if removed >= 0: 1 else: 0)

proc componentsAfterPair(piece: Piece, n, poleU, poleV: int,
                         component: var array[MaxN, int], componentCount: var int) =
  for v in 0 ..< n: component[v] = -1
  componentCount = 0
  var queue: array[MaxN, int]
  for start in 0 ..< n:
    if start == poleU or start == poleV or component[start] >= 0: continue
    var head = 0
    var tail = 1
    component[start] = componentCount
    queue[0] = start
    while head < tail:
      let u = queue[head]
      inc head
      for edgeId in 0 ..< piece.edgeCount:
        let edge = piece.edges[edgeId]
        if edge.u == poleU or edge.u == poleV or edge.v == poleU or edge.v == poleV: continue
        var other = -1
        if edge.u == u: other = edge.v
        elif edge.v == u: other = edge.u
        if other >= 0 and component[other] < 0:
          component[other] = componentCount
          queue[tail] = other
          inc tail
    inc componentCount

proc findSplit(piece: Piece, n: int, chosenU, chosenV: var int,
               leftEdge: var array[MaxM, bool]): bool =
  let edgeCount = piece.edgeCount
  for u in 0 ..< n:
    for v in (u + 1) ..< n:
      var component: array[MaxN, int]
      var componentCount: int
      componentsAfterPair(piece, n, u, v, component, componentCount)
      var edgeClass: array[MaxM, int]
      var sizes: array[MaxM, int]
      var directCount = 0
      for edgeId in 0 ..< edgeCount:
        let edge = piece.edges[edgeId]
        if (edge.u == u and edge.v == v) or (edge.u == v and edge.v == u):
          edgeClass[edgeId] = componentCount + directCount
          inc directCount
        else:
          let endpoint = if edge.u != u and edge.u != v: edge.u else: edge.v
          if component[endpoint] < 0: return false
          edgeClass[edgeId] = component[endpoint]
        if edgeClass[edgeId] < 0 or edgeClass[edgeId] >= MaxM: return false
        inc sizes[edgeClass[edgeId]]
      let classCount = componentCount + directCount
      var selected = -1
      for c in 0 ..< classCount:
        if sizes[c] >= 2 and sizes[c] <= edgeCount - 2:
          selected = c
          break
      var useFirstTwo = selected < 0 and classCount >= 4 and classCount == edgeCount
      if useFirstTwo:
        for c in 0 ..< classCount:
          if sizes[c] != 1: useFirstTwo = false
      if selected < 0 and not useFirstTwo: continue
      for edgeId in 0 ..< edgeCount:
        leftEdge[edgeId] = if selected >= 0: edgeClass[edgeId] == selected else: edgeClass[edgeId] < 2
      chosenU = u
      chosenV = v
      return true
  false

proc pieceKind(piece: Piece): int =
  var present: array[MaxN, bool]
  var vertexCount = 0
  for edgeId in 0 ..< piece.edgeCount:
    let edge = piece.edges[edgeId]
    if not present[edge.u]: present[edge.u] = true; inc vertexCount
    if not present[edge.v]: present[edge.v] = true; inc vertexCount
  if vertexCount == 2 and piece.edgeCount >= 3: return KindP
  if vertexCount == 3 and piece.edgeCount == 3:
    var pair: array[MaxN * MaxN, bool]
    for edgeId in 0 ..< 3:
      let edge = piece.edges[edgeId]
      pair[edge.u * MaxN + edge.v] = true
      pair[edge.v * MaxN + edge.u] = true
    var count = 0
    for u in 0 ..< MaxN:
      for v in (u + 1) ..< MaxN:
        if pair[u * MaxN + v]: inc count
    if count == 3: return KindS
  KindR

proc findRoot(parent: var array[MaxPieces, int], item: int): int =
  var current = item
  while parent[current] != current:
    parent[current] = parent[parent[current]]
    current = parent[current]
  current

proc unite(parent: var array[MaxPieces, int], left, right: int) =
  let a = findRoot(parent, left)
  let b = findRoot(parent, right)
  if a != b: parent[b] = a

proc componentCountWithoutPair(adjacency: array[MaxN * MaxN, bool], n, a, b: int): int =
  var seen: array[MaxN, bool]
  var queue: array[MaxN, int]
  var count = 0
  for start in 0 ..< n:
    if start == a or start == b or seen[start]: continue
    inc count
    var head = 0
    var tail = 1
    seen[start] = true
    queue[0] = start
    while head < tail:
      let u = queue[head]
      inc head
      for v in 0 ..< n:
        if v != a and v != b and adjacency[u * MaxN + v] and not seen[v]:
          seen[v] = true
          queue[tail] = v
          inc tail
  count

proc two_vertex_cuts_spqr*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "two_vertex_cuts_spqr".} =
  if input.isNil or length < csize_t(2) or length > csize_t(MaxInput): return -1
  if input[0] < 3 or input[0] > MaxN or input[1] < 3 or input[1] > MaxM: return -1
  let n = int(input[0])
  let m = int(input[1])
  if int(length) != 2 + n + 2 * m: return -1
  var weights: array[MaxN, int64]
  for v in 0 ..< n:
    weights[v] = input[2 + v]
    if weights[v] < 0 or weights[v] > 1_000_000: return -1
  var adjacency: array[MaxN * MaxN, bool]
  var pieces: array[MaxPieces, Piece]
  pieces[0].edgeCount = m
  let offset = 2 + n
  for edgeId in 0 ..< m:
    let left = input[offset + 2 * edgeId]
    let right = input[offset + 2 * edgeId + 1]
    if left < 0 or left >= n or right < 0 or right >= n or left == right: return -1
    let u = int(left)
    let v = int(right)
    if adjacency[u * MaxN + v]: return -1
    adjacency[u * MaxN + v] = true
    adjacency[v * MaxN + u] = true
    pieces[0].edges[edgeId] = EdgeRef(u: u, v: v, pairId: -1, real: true)
  for removed in -1 ..< n:
    if not connectedWithout(adjacency, n, removed): return -1

  var pieceCount = 1
  var splitCount = 0
  var pairU: array[MaxSplits, int]
  var pairV: array[MaxSplits, int]
  var isLeaf: array[MaxPieces, bool]
  var index = 0
  while index < pieceCount:
    var leftEdge: array[MaxM, bool]
    var u = 0
    var v = 0
    if not findSplit(pieces[index], n, u, v, leftEdge):
      isLeaf[index] = true
      inc index
      continue
    if splitCount >= MaxSplits or pieceCount + 2 > MaxPieces: return -1
    let leftIndex = pieceCount
    let rightIndex = pieceCount + 1
    pieceCount += 2
    pieces[leftIndex].edgeCount = 0
    pieces[rightIndex].edgeCount = 0
    for edgeId in 0 ..< pieces[index].edgeCount:
      if leftEdge[edgeId]:
        pieces[leftIndex].edges[pieces[leftIndex].edgeCount] = pieces[index].edges[edgeId]
        inc pieces[leftIndex].edgeCount
      else:
        pieces[rightIndex].edges[pieces[rightIndex].edgeCount] = pieces[index].edges[edgeId]
        inc pieces[rightIndex].edgeCount
    let pairId = splitCount
    pairU[pairId] = u
    pairV[pairId] = v
    inc splitCount
    pieces[leftIndex].edges[pieces[leftIndex].edgeCount] = EdgeRef(u: u, v: v, pairId: pairId, real: false)
    inc pieces[leftIndex].edgeCount
    pieces[rightIndex].edges[pieces[rightIndex].edgeCount] = EdgeRef(u: u, v: v, pairId: pairId, real: false)
    inc pieces[rightIndex].edgeCount
    if pieces[leftIndex].edgeCount < 3 or pieces[rightIndex].edgeCount < 3: return -1
    inc index

  var kind: array[MaxPieces, int]
  var firstLeaf: array[MaxSplits, int]
  var secondLeaf: array[MaxSplits, int]
  var occurrences: array[MaxSplits, int]
  for id in 0 ..< MaxSplits: firstLeaf[id] = -1; secondLeaf[id] = -1
  var parent: array[MaxPieces, int]
  for p in 0 ..< pieceCount:
    parent[p] = p
    if isLeaf[p]: kind[p] = pieceKind(pieces[p])
  for p in 0 ..< pieceCount:
    if not isLeaf[p]: continue
    for edgeId in 0 ..< pieces[p].edgeCount:
      let edge = pieces[p].edges[edgeId]
      if edge.real: continue
      if edge.pairId < 0 or edge.pairId >= splitCount: return -1
      inc occurrences[edge.pairId]
      if occurrences[edge.pairId] == 1: firstLeaf[edge.pairId] = p
      elif occurrences[edge.pairId] == 2: secondLeaf[edge.pairId] = p
      else: return -1
  for id in 0 ..< splitCount:
    if occurrences[id] != 2 or firstLeaf[id] == secondLeaf[id]: return -1
    let a = firstLeaf[id]
    let b = secondLeaf[id]
    if kind[a] == kind[b] and (kind[a] == KindS or kind[a] == KindP): unite(parent, a, b)

  var candidate: array[MaxN * MaxN, bool]
  for id in 0 ..< splitCount: candidate[pairU[id] * MaxN + pairV[id]] = true
  for leaf in 0 ..< pieceCount:
    if not isLeaf[leaf] or findRoot(parent, leaf) != leaf: continue
    if kind[leaf] == KindS:
      var inGroup: array[MaxN, bool]
      var skeleton: array[MaxN * MaxN, bool]
      for member in 0 ..< pieceCount:
        if not isLeaf[member] or findRoot(parent, member) != leaf: continue
        for edgeId in 0 ..< pieces[member].edgeCount:
          let edge = pieces[member].edges[edgeId]
          if not edge.real and findRoot(parent, firstLeaf[edge.pairId]) == leaf and
              findRoot(parent, secondLeaf[edge.pairId]) == leaf: continue
          inGroup[edge.u] = true
          inGroup[edge.v] = true
          skeleton[edge.u * MaxN + edge.v] = true
          skeleton[edge.v * MaxN + edge.u] = true
      for u in 0 ..< n:
        for v in (u + 1) ..< n:
          if inGroup[u] and inGroup[v] and not skeleton[u * MaxN + v]: candidate[u * MaxN + v] = true
    elif kind[leaf] == KindP:
      var first = -1
      var second = -1
      for member in 0 ..< pieceCount:
        if not isLeaf[member] or findRoot(parent, member) != leaf: continue
        for edgeId in 0 ..< pieces[member].edgeCount:
          for endpoint in [pieces[member].edges[edgeId].u, pieces[member].edges[edgeId].v]:
            if first < 0: first = endpoint
            elif endpoint != first and second < 0: second = endpoint
            elif endpoint != first and endpoint != second: return -1
      if first < 0 or second < 0: return -1
      let lo = min(first, second)
      let hi = max(first, second)
      candidate[lo * MaxN + hi] = true

  var total: int64 = 0
  for u in 0 ..< n:
    for v in (u + 1) ..< n:
      if not candidate[u * MaxN + v]: continue
      let components = componentCountWithoutPair(adjacency, n, u, v)
      if components > 1:
        let term = (weights[u] mod Modulus) * (weights[v] mod Modulus) mod Modulus
        total = (total + term * int64(components - 1)) mod Modulus
  total
