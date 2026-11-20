const
  MaxTextLength = 64
  MaxInputLength = 66
  MaxSymbols = MaxTextLength + 1
  MaxNodes = 130
  OpenEnd = -1

type
  SuffixNode = object
    edgeStart: int
    edgeEnd: int # Exclusive for internal edges; OpenEnd for leaves.
    suffixLink: int
    suffixStart: int
    leaf: bool
    children: array[5, int]

  UkkonenState = object
    symbols: array[MaxSymbols, int]
    symbolCount: int
    leafEnd: int
    nodes: array[MaxNodes, SuffixNode]
    nodeCount: int

proc newNode(state: var UkkonenState, edgeStart, edgeEnd: int,
    isLeaf: bool, suffixStart: int): int =
  if state.nodeCount >= MaxNodes: return -1
  result = state.nodeCount
  inc state.nodeCount
  state.nodes[result].edgeStart = edgeStart
  state.nodes[result].edgeEnd = edgeEnd
  state.nodes[result].suffixLink = 0
  state.nodes[result].suffixStart = suffixStart
  state.nodes[result].leaf = isLeaf
  for symbol in 0..4: state.nodes[result].children[symbol] = -1

proc edgeLength(state: var UkkonenState, node: int): int =
  let edgeEnd = if state.nodes[node].leaf: state.leafEnd + 1 else: state.nodes[node].edgeEnd
  edgeEnd - state.nodes[node].edgeStart

proc buildOnlineTree(state: var UkkonenState): bool =
  let root = newNode(state, 0, 0, false, -1)
  if root != 0: return false
  state.nodes[root].suffixLink = root

  var activeNode = root
  var activeEdge = 0
  var activeLength = 0
  var remaining = 0
  state.leafEnd = -1

  for position in 0..<state.symbolCount:
    state.leafEnd = position
    inc remaining
    var lastInternal = -1

    while remaining > 0:
      if activeLength == 0: activeEdge = position
      let activeSymbol = state.symbols[activeEdge]
      var next = state.nodes[activeNode].children[activeSymbol]

      if next < 0:
        let suffixStart = position - remaining + 1
        next = newNode(state, position, OpenEnd, true, suffixStart)
        if next < 0: return false
        state.nodes[activeNode].children[activeSymbol] = next
        if lastInternal >= 0:
          state.nodes[lastInternal].suffixLink = activeNode
          lastInternal = -1
      else:
        let nextLength = edgeLength(state, next)
        if activeLength >= nextLength:
          activeEdge += nextLength
          activeLength -= nextLength
          activeNode = next
          continue

        let nextStart = state.nodes[next].edgeStart
        if state.symbols[nextStart + activeLength] == state.symbols[position]:
          if lastInternal >= 0 and activeNode != root:
            state.nodes[lastInternal].suffixLink = activeNode
            lastInternal = -1
          inc activeLength
          break

        let split = newNode(state, nextStart, nextStart + activeLength, false, -1)
        if split < 0: return false
        state.nodes[activeNode].children[activeSymbol] = split
        state.nodes[next].edgeStart += activeLength
        let oldSymbol = state.symbols[state.nodes[next].edgeStart]
        state.nodes[split].children[oldSymbol] = next

        let suffixStart = position - remaining + 1
        let leaf = newNode(state, position, OpenEnd, true, suffixStart)
        if leaf < 0: return false
        state.nodes[split].children[state.symbols[position]] = leaf
        if lastInternal >= 0: state.nodes[lastInternal].suffixLink = split
        lastInternal = split

      dec remaining
      if activeNode == root and activeLength > 0:
        dec activeLength
        activeEdge = position - remaining + 1
      elif activeNode != root:
        activeNode = state.nodes[activeNode].suffixLink
  true

proc pushToken(rank, checksum: var int64, token: int64) =
  inc rank
  checksum += rank * token

proc emitNode(state: var UkkonenState, node: int, isRoot: bool,
    rank, checksum, distinctSubstrings: var int64) =
  if isRoot: pushToken(rank, checksum, 0)
  for symbol in 0..4:
    let child = state.nodes[node].children[symbol]
    if child < 0: continue
    let edgeEnd = if state.nodes[child].leaf: state.leafEnd + 1 else: state.nodes[child].edgeEnd
    let edgeStart = state.nodes[child].edgeStart
    let edgeLength = edgeEnd - edgeStart
    pushToken(rank, checksum, 1)
    pushToken(rank, checksum, int64(edgeLength))
    for index in edgeStart..<edgeEnd:
      let value = state.symbols[index]
      pushToken(rank, checksum, int64(value + 1))
      if value != 4: inc distinctSubstrings
    if state.nodes[child].leaf:
      pushToken(rank, checksum, 2)
      pushToken(rank, checksum, int64(state.nodes[child].suffixStart + 1))
    else:
      pushToken(rank, checksum, 3)
      emitNode(state, child, false, rank, checksum, distinctSubstrings)
      pushToken(rank, checksum, 4)
  if isRoot: pushToken(rank, checksum, 4)

proc ukkonen_suffix_tree*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "ukkonen_suffix_tree".} =
  if input.isNil or length < 1 or length > csize_t(MaxInputLength): return -1
  let textLengthValue = input[0]
  if textLengthValue < 0 or textLengthValue > MaxTextLength: return -1
  let textLength = int(textLengthValue)
  if int(length) != textLength + 1: return -1

  var state: UkkonenState
  for index in 0..<textLength:
    let symbol = input[index + 1]
    if symbol < 0 or symbol > 3: return -1
    state.symbols[index] = int(symbol)
  state.symbols[textLength] = 4
  state.symbolCount = textLength + 1
  if not buildOnlineTree(state): return -1

  var rank = 0'i64
  var checksum = 0'i64
  var distinctSubstrings = 0'i64
  emitNode(state, 0, true, rank, checksum, distinctSubstrings)
  int64(state.nodeCount) * (1'i64 shl 44) + distinctSubstrings * (1'i64 shl 32) + checksum
