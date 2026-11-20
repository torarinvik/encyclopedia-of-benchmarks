const MaxOperations = 64
const MaxItems = 32
const MaxParseableInputLength = 194

proc rankOf(node: int, ranks: array[MaxOperations, int]): int =
  if node < 0: -1 else: ranks[node]

proc minimumRoot(nodeCount: int, keys: array[MaxOperations, int64],
    items: array[MaxOperations, int], parents: array[MaxOperations, int],
    alive: array[MaxOperations, bool]): int =
  var best = -1
  for node in 0..<nodeCount:
    if alive[node] and parents[node] == -1:
      if best < 0 or keys[node] < keys[best] or
          (keys[node] == keys[best] and (items[node] < items[best] or
            (items[node] == items[best] and node < best))):
        best = node
  best

proc fairLink(first, second: int, keys: array[MaxOperations, int64],
    items: array[MaxOperations, int], left: var array[MaxOperations, int],
    right: var array[MaxOperations, int], ranks: var array[MaxOperations, int],
    parents: var array[MaxOperations, int]) =
  var winner = first
  var loser = second
  if keys[second] < keys[first] or
      (keys[second] == keys[first] and (items[second] < items[first] or
        (items[second] == items[first] and second < first))):
    winner = second
    loser = first
  let oldLeft = left[winner]
  left[winner] = loser
  parents[loser] = winner
  right[loser] = oldLeft
  if oldLeft >= 0: parents[oldLeft] = loser
  inc ranks[winner]

proc consolidateFairRoots(nodeCount: int, keys: array[MaxOperations, int64],
    items: array[MaxOperations, int], left: var array[MaxOperations, int],
    right: var array[MaxOperations, int], ranks: var array[MaxOperations, int],
    parents: var array[MaxOperations, int], alive: array[MaxOperations, bool]) =
  while true:
    var duplicateRank = -1
    for first in 0..<nodeCount:
      if not alive[first] or parents[first] != -1: continue
      for second in (first + 1)..<nodeCount:
        if alive[second] and parents[second] == -1 and ranks[second] == ranks[first] and
            (duplicateRank < 0 or ranks[first] < duplicateRank):
          duplicateRank = ranks[first]
    if duplicateRank < 0: break
    var firstRoot = -1
    var secondRoot = -1
    for node in 0..<nodeCount:
      if alive[node] and parents[node] == -1 and ranks[node] == duplicateRank:
        if firstRoot < 0:
          firstRoot = node
        else:
          secondRoot = node
          break
    if firstRoot < 0 or secondRoot < 0: break
    fairLink(firstRoot, secondRoot, keys, items, left, right, ranks, parents)

proc rank_pairing_heap*(input: ptr UncheckedArray[int64],
    length: csize_t): int64 {.cdecl, exportc: "rank_pairing_heap".} =
  if input.isNil or length < csize_t(1) or length > csize_t(MaxParseableInputLength): return -1
  let operationCountValue = input[0]
  if operationCountValue < 0'i64 or operationCountValue > int64(MaxOperations): return -1
  let operationCount = int(operationCountValue)
  if length != csize_t(1 + 3 * operationCount): return -1

  var keys: array[MaxOperations, int64]
  var items: array[MaxOperations, int]
  var ranks: array[MaxOperations, int]
  var left: array[MaxOperations, int]
  var right: array[MaxOperations, int]
  var parents: array[MaxOperations, int]
  var alive: array[MaxOperations, bool]
  var itemNodes: array[MaxItems, int]
  var active: array[MaxItems, bool]
  for node in 0..<MaxOperations:
    items[node] = -1
    left[node] = -1
    right[node] = -1
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
      left[node] = -1
      right[node] = -1
      parents[node] = -1
      alive[node] = true
      itemNodes[item] = node
      active[item] = true
    elif opcode == 2'i64:
      if itemValue < 0'i64 or itemValue >= int64(MaxItems) or
          value < 0'i64 or value > 1_000_000'i64: return -1
      let item = int(itemValue)
      if not active[item]: return -1
      let node = itemNodes[item]
      if value >= keys[node]: return -1
      keys[node] = value
      if parents[node] >= 0:
        let oldParent = parents[node]
        let nextSibling = right[node]
        if left[oldParent] == node:
          left[oldParent] = nextSibling
        else:
          right[oldParent] = nextSibling
        if nextSibling >= 0: parents[nextSibling] = oldParent
        parents[node] = -1
        right[node] = -1
        ranks[node] = rankOf(left[node], ranks) + 1

        var ancestor = oldParent
        while ancestor >= 0:
          if parents[ancestor] < 0:
            ranks[ancestor] = rankOf(left[ancestor], ranks) + 1
            break
          let leftRank = rankOf(left[ancestor], ranks)
          let rightRank = rankOf(right[ancestor], ranks)
          var newRank: int
          if leftRank != rightRank:
            newRank = max(leftRank, rightRank)
          else:
            newRank = leftRank + 1
          if newRank >= ranks[ancestor]: break
          ranks[ancestor] = newRank
          ancestor = parents[ancestor]
    elif opcode == 3'i64:
      if itemValue != 0'i64 or value != 0'i64: return -1
      let node = minimumRoot(nodeCount, keys, items, parents, alive)
      if node < 0: return -1
      let removedItem = items[node]
      result += int64(operationIndex + 1) * (keys[node] + 1) + int64(removedItem)
      active[removedItem] = false
      itemNodes[removedItem] = -1

      var child = left[node]
      while child >= 0:
        let nextSibling = right[child]
        right[child] = -1
        parents[child] = -1
        ranks[child] = rankOf(left[child], ranks) + 1
        child = nextSibling
      alive[node] = false
      parents[node] = -2
      left[node] = -1
      right[node] = -1
      items[node] = -1
      consolidateFairRoots(nodeCount, keys, items, left, right, ranks, parents, alive)
    elif opcode == 4'i64:
      if itemValue != 0'i64 or value != 0'i64: return -1
      let node = minimumRoot(nodeCount, keys, items, parents, alive)
      if node < 0: return -1
      result += int64(operationIndex + 1) * (keys[node] + 1) + int64(items[node])
    else:
      return -1
  result
