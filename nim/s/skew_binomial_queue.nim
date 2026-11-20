const MaxOperations = 64
const MaxItems = 32
const MaxParseableInputLength = 194
const MaxRankBuckets = MaxOperations + 1

proc lessNode(first, second: int, keys: array[MaxOperations, int64],
    serials: array[MaxOperations, int], items: array[MaxOperations, int]): bool =
  keys[first] < keys[second] or
    (keys[first] == keys[second] and (serials[first] < serials[second] or
      (serials[first] == serials[second] and (items[first] < items[second] or
        (items[first] == items[second] and first < second))))

proc rootsBefore(first, second: int, ranks: array[MaxOperations, int],
    serials: array[MaxOperations, int]): bool =
  ranks[first] < ranks[second] or
    (ranks[first] == ranks[second] and (serials[first] < serials[second] or
      (serials[first] == serials[second] and first < second)))

proc collectRoots(nodeCount: int, ranks: array[MaxOperations, int],
    serials: array[MaxOperations, int], parents: array[MaxOperations, int],
    alive: array[MaxOperations, bool], roots: var array[MaxOperations, int]): int =
  var count = 0
  for node in 0..<nodeCount:
    if alive[node] and parents[node] == -1:
      roots[count] = node
      inc count
  for i in 1..<count:
    let key = roots[i]
    var j = i
    while j > 0 and rootsBefore(key, roots[j - 1], ranks, serials):
      roots[j] = roots[j - 1]
      dec j
    roots[j] = key
  count

proc simpleLink(first, second: int, keys: array[MaxOperations, int64],
    serials: array[MaxOperations, int], items: array[MaxOperations, int],
    firstChild: var array[MaxOperations, int], nextSibling: var array[MaxOperations, int],
    ranks: var array[MaxOperations, int], parents: var array[MaxOperations, int]): int =
  var winner = first
  var loser = second
  if lessNode(second, first, keys, serials, items):
    winner = second
    loser = first
  nextSibling[loser] = firstChild[winner]
  firstChild[winner] = loser
  parents[loser] = winner
  inc ranks[winner]
  winner

proc skewLink(singleton, first, second: int, keys: array[MaxOperations, int64],
    serials: array[MaxOperations, int], items: array[MaxOperations, int],
    firstChild: var array[MaxOperations, int], nextSibling: var array[MaxOperations, int],
    ranks: var array[MaxOperations, int], parents: var array[MaxOperations, int]): int =
  let resultRank = ranks[first] + 1
  var winner: int
  if lessNode(singleton, first, keys, serials, items) and
      lessNode(singleton, second, keys, serials, items):
    winner = singleton
    firstChild[winner] = first
    nextSibling[first] = second
    nextSibling[second] = -1
    parents[first] = winner
    parents[second] = winner
  else:
    if lessNode(first, second, keys, serials, items):
      winner = first
    else:
      winner = second
    let loser = if winner == first: second else: first
    let oldChildren = firstChild[winner]
    firstChild[winner] = singleton
    nextSibling[singleton] = loser
    nextSibling[loser] = oldChildren
    parents[singleton] = winner
    parents[loser] = winner
  parents[winner] = -1
  ranks[winner] = resultRank
  winner

proc insertSingleton(node, nodeCount: int, ranks: var array[MaxOperations, int],
    serials: array[MaxOperations, int], parents: var array[MaxOperations, int],
    alive: array[MaxOperations, bool], keys: array[MaxOperations, int64],
    items: array[MaxOperations, int], firstChild: var array[MaxOperations, int],
    nextSibling: var array[MaxOperations, int]) =
  parents[node] = -2
  var roots: array[MaxOperations, int]
  let rootCount = collectRoots(nodeCount, ranks, serials, parents, alive, roots)
  if rootCount >= 2 and ranks[roots[0]] == ranks[roots[1]]:
    discard skewLink(node, roots[0], roots[1], keys, serials, items,
      firstChild, nextSibling, ranks, parents)
  else:
    parents[node] = -1

proc normalizeEqualRanks(nodeCount: int, inputRoots: array[MaxOperations, int],
    rootCount: int, keys: array[MaxOperations, int64], serials: array[MaxOperations, int],
    items: array[MaxOperations, int], firstChild: var array[MaxOperations, int],
    nextSibling: var array[MaxOperations, int], ranks: var array[MaxOperations, int],
    parents: var array[MaxOperations, int]) =
  var orderedRoots = inputRoots
  for i in 1..<rootCount:
    let key = orderedRoots[i]
    var j = i
    while j > 0 and rootsBefore(key, orderedRoots[j - 1], ranks, serials):
      orderedRoots[j] = orderedRoots[j - 1]
      dec j
    orderedRoots[j] = key

  var buckets: array[MaxRankBuckets, int]
  for rank in 0..<MaxRankBuckets: buckets[rank] = -1
  for i in 0..<rootCount:
    var current = orderedRoots[i]
    while true:
      let rank = ranks[current]
      if rank < 0 or rank >= MaxRankBuckets: return
      if buckets[rank] < 0:
        buckets[rank] = current
        break
      let previous = buckets[rank]
      buckets[rank] = -1
      current = simpleLink(previous, current, keys, serials, items,
        firstChild, nextSibling, ranks, parents)

proc minimumRoot(nodeCount: int, keys: array[MaxOperations, int64],
    serials: array[MaxOperations, int], items: array[MaxOperations, int],
    parents: array[MaxOperations, int], alive: array[MaxOperations, bool]): int =
  var best = -1
  for node in 0..<nodeCount:
    if alive[node] and parents[node] == -1 and
        (best < 0 or lessNode(node, best, keys, serials, items)):
      best = node
  best

proc skew_binomial_queue*(input: ptr UncheckedArray[int64],
    length: csize_t): int64 {.cdecl, exportc: "skew_binomial_queue".} =
  if input.isNil or length < csize_t(1) or length > csize_t(MaxParseableInputLength): return -1
  let operationCountValue = input[0]
  if operationCountValue < 0'i64 or operationCountValue > int64(MaxOperations): return -1
  let operationCount = int(operationCountValue)
  if length != csize_t(1 + 3 * operationCount): return -1

  var keys: array[MaxOperations, int64]
  var serials: array[MaxOperations, int]
  var items: array[MaxOperations, int]
  var ranks: array[MaxOperations, int]
  var firstChild: array[MaxOperations, int]
  var nextSibling: array[MaxOperations, int]
  var parents: array[MaxOperations, int]
  var alive: array[MaxOperations, bool]
  var itemNodes: array[MaxItems, int]
  var active: array[MaxItems, bool]
  for node in 0..<MaxOperations:
    items[node] = -1
    firstChild[node] = -1
    nextSibling[node] = -1
    parents[node] = -2
  for item in 0..<MaxItems: itemNodes[item] = -1

  var nodeCount = 0
  var insertionSerial = 0
  var result = 0'i64
  for operationIndex in 0..<operationCount:
    let offset = 1 + 3 * operationIndex
    let opcode = input[offset]
    let itemValue = input[offset + 1]
    let key = input[offset + 2]
    if opcode == 1'i64:
      if itemValue < 0'i64 or itemValue >= int64(MaxItems) or
          key < 0'i64 or key > 1_000_000'i64: return -1
      let item = int(itemValue)
      if active[item] or nodeCount >= MaxOperations: return -1
      let node = nodeCount
      nodeCount += 1
      keys[node] = key
      serials[node] = insertionSerial
      inc insertionSerial
      items[node] = item
      ranks[node] = 0
      firstChild[node] = -1
      nextSibling[node] = -1
      parents[node] = -1
      alive[node] = true
      itemNodes[item] = node
      active[item] = true
      insertSingleton(node, nodeCount, ranks, serials, parents, alive, keys,
        items, firstChild, nextSibling)
    elif opcode == 2'i64 or opcode == 3'i64:
      if itemValue != 0'i64 or key != 0'i64: return -1
      let node = minimumRoot(nodeCount, keys, serials, items, parents, alive)
      if node < 0: return -1
      let item = items[node]
      result += int64(operationIndex + 1) * (keys[node] + 1) + int64(item)
      if opcode == 2'i64: continue

      active[item] = false
      itemNodes[item] = -1
      var children: array[MaxOperations, int]
      var childCount = 0
      var child = firstChild[node]
      while child >= 0:
        let following = nextSibling[child]
        parents[child] = -1
        nextSibling[child] = -1
        children[childCount] = child
        inc childCount
        child = following
      alive[node] = false
      parents[node] = -2
      items[node] = -1
      firstChild[node] = -1
      nextSibling[node] = -1

      var childMembership: array[MaxOperations, bool]
      var zeroChildren: array[MaxOperations, int]
      var zeroCount = 0
      var positiveChildren: array[MaxOperations, int]
      var positiveCount = 0
      for i in 0..<childCount:
        let descendant = children[i]
        childMembership[descendant] = true
        if ranks[descendant] == 0:
          zeroChildren[zeroCount] = descendant
          inc zeroCount
        else:
          positiveChildren[positiveCount] = descendant
          inc positiveCount
      for i in 1..<zeroCount:
        let valueNode = zeroChildren[i]
        var j = i
        while j > 0 and (serials[zeroChildren[j - 1]] > serials[valueNode] or
            (serials[zeroChildren[j - 1]] == serials[valueNode] and zeroChildren[j - 1] > valueNode)):
          zeroChildren[j] = zeroChildren[j - 1]
          dec j
        zeroChildren[j] = valueNode

      var roots: array[MaxOperations, int]
      var rootCount = 0
      for candidate in 0..<nodeCount:
        if alive[candidate] and parents[candidate] == -1 and not childMembership[candidate]:
          roots[rootCount] = candidate
          inc rootCount
      for i in 0..<positiveCount:
        roots[rootCount] = positiveChildren[i]
        inc rootCount
      normalizeEqualRanks(nodeCount, roots, rootCount, keys, serials, items,
        firstChild, nextSibling, ranks, parents)
      for i in 0..<zeroCount:
        insertSingleton(zeroChildren[i], nodeCount, ranks, serials, parents, alive,
          keys, items, firstChild, nextSibling)
    else:
      return -1
  result
