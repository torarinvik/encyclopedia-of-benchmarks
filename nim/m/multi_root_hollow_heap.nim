const MaxOperations = 64
const MaxItems = 32
const MaxParseableInputLength = 194

proc minimumRoot(nodeCount: int, keys: array[MaxOperations, int64],
    items: array[MaxOperations, int], parents: array[MaxOperations, int],
    alive: array[MaxOperations, bool]): int =
  var best = -1
  for node in 0..<nodeCount:
    if alive[node] and parents[node] == -1 and items[node] >= 0:
      if best < 0 or keys[node] < keys[best] or
          (keys[node] == keys[best] and (items[node] < items[best] or
            (items[node] == items[best] and node < best))):
        best = node
  best

proc destroyHollowRootsAndConsolidate(nodeCount: int,
    keys: array[MaxOperations, int64], items: var array[MaxOperations, int],
    ranks: var array[MaxOperations, int], parents: var array[MaxOperations, int],
    alive: var array[MaxOperations, bool]) =
  while true:
    var hollowRoot = -1
    for node in 0..<nodeCount:
      if alive[node] and parents[node] == -1 and items[node] == -1:
        hollowRoot = node
        break
    if hollowRoot < 0: break
    for child in 0..<nodeCount:
      if alive[child] and parents[child] == hollowRoot: parents[child] = -1
    alive[hollowRoot] = false
    parents[hollowRoot] = -2

  while true:
    var duplicateRank = -1
    for first in 0..<nodeCount:
      if not alive[first] or parents[first] != -1 or items[first] < 0: continue
      for second in (first + 1)..<nodeCount:
        if alive[second] and parents[second] == -1 and items[second] >= 0 and
            ranks[second] == ranks[first] and
            (duplicateRank < 0 or ranks[first] < duplicateRank):
          duplicateRank = ranks[first]
    if duplicateRank < 0: break

    var firstRoot = -1
    var secondRoot = -1
    for node in 0..<nodeCount:
      if alive[node] and parents[node] == -1 and items[node] >= 0 and ranks[node] == duplicateRank:
        if firstRoot < 0:
          firstRoot = node
        else:
          secondRoot = node
          break
    if firstRoot < 0 or secondRoot < 0: break
    var winner = firstRoot
    var loser = secondRoot
    if keys[secondRoot] < keys[firstRoot] or
        (keys[secondRoot] == keys[firstRoot] and (items[secondRoot] < items[firstRoot] or
          (items[secondRoot] == items[firstRoot] and secondRoot < firstRoot))):
      winner = secondRoot
      loser = firstRoot
    parents[loser] = winner
    inc ranks[winner]

proc multi_root_hollow_heap*(input: ptr UncheckedArray[int64],
    length: csize_t): int64 {.cdecl, exportc: "multi_root_hollow_heap".} =
  if input.isNil or length < csize_t(1) or length > csize_t(MaxParseableInputLength): return -1
  let operationCountValue = input[0]
  if operationCountValue < 0'i64 or operationCountValue > int64(MaxOperations): return -1
  let operationCount = int(operationCountValue)
  if length != csize_t(1 + 3 * operationCount): return -1

  var keys: array[MaxOperations, int64]
  var items: array[MaxOperations, int]
  var ranks: array[MaxOperations, int]
  var parents: array[MaxOperations, int]
  var alive: array[MaxOperations, bool]
  var itemNodes: array[MaxItems, int]
  var active: array[MaxItems, bool]
  for node in 0..<MaxOperations:
    items[node] = -1
    parents[node] = -2
  for item in 0..<MaxItems: itemNodes[item] = -1

  var nodeCount = 0
  var result = 0'i64
  for operationIndex in 0..<operationCount:
    let offset = 1 + 3 * operationIndex
    let opcode = input[offset]
    let itemValue = input[offset + 1]
    let value = input[offset + 2]
    if opcode == 1'i64:
      if itemValue < 0'i64 or itemValue >= int64(MaxItems) or
          value < 0'i64 or value > 1_000_000'i64: return -1
      let item = int(itemValue)
      if active[item] or nodeCount >= MaxOperations: return -1
      let node = nodeCount
      inc nodeCount
      keys[node] = value
      items[node] = item
      ranks[node] = 0
      parents[node] = -1
      alive[node] = true
      itemNodes[item] = node
      active[item] = true
    elif opcode == 2'i64:
      if itemValue < 0'i64 or itemValue >= int64(MaxItems) or
          value < 0'i64 or value > 1_000_000'i64: return -1
      let item = int(itemValue)
      if not active[item] or nodeCount >= MaxOperations: return -1
      let oldNode = itemNodes[item]
      if value >= keys[oldNode]: return -1
      let oldRank = ranks[oldNode]
      let newRank = max(oldRank - 2, 0)
      items[oldNode] = -1
      let newNode = nodeCount
      inc nodeCount
      keys[newNode] = value
      items[newNode] = item
      ranks[newNode] = newRank
      parents[newNode] = -1
      alive[newNode] = true
      for child in 0..<newNode:
        if alive[child] and parents[child] == oldNode and ranks[child] < newRank:
          parents[child] = newNode
      itemNodes[item] = newNode
    elif opcode == 3'i64:
      if itemValue != 0'i64 or value != 0'i64: return -1
      let node = minimumRoot(nodeCount, keys, items, parents, alive)
      if node < 0: return -1
      let item = items[node]
      active[item] = false
      itemNodes[item] = -1
      items[node] = -1
      result += int64(operationIndex + 1) * (keys[node] + 1) + int64(item)
      destroyHollowRootsAndConsolidate(nodeCount, keys, items, ranks, parents, alive)
    elif opcode == 4'i64:
      if itemValue != 0'i64 or value != 0'i64: return -1
      let node = minimumRoot(nodeCount, keys, items, parents, alive)
      if node < 0: return -1
      result += int64(operationIndex + 1) * (keys[node] + 1) + int64(items[node])
    elif opcode == 5'i64:
      if itemValue < 0'i64 or itemValue >= int64(MaxItems) or value != 0'i64: return -1
      let item = int(itemValue)
      if not active[item]: return -1
      let node = itemNodes[item]
      let wasMinimum = node == minimumRoot(nodeCount, keys, items, parents, alive)
      active[item] = false
      itemNodes[item] = -1
      items[node] = -1
      if wasMinimum:
        destroyHollowRootsAndConsolidate(nodeCount, keys, items, ranks, parents, alive)
    else:
      return -1
  result
