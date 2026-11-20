const
  MaxStrings = 16
  MaxStringLength = 8
  MaxInputWords = 145
  MaxTrieNodes = 129
  BucketThreshold = 3

type
  BurstNode = object
    depth: int
    burst: bool
    children: array[4, int]
    bucket: array[MaxStrings, int]
    bucketCount: int
    terminal: array[MaxStrings, int]
    terminalCount: int

  BurstState = object
    nodes: array[MaxTrieNodes, BurstNode]
    nodeCount: int
    lengths: array[MaxStrings, int]
    bytes: array[MaxStrings * MaxStringLength, int]

proc newNode(state: var BurstState, depth: int): int =
  if state.nodeCount >= MaxTrieNodes: return -1
  result = state.nodeCount
  inc state.nodeCount
  state.nodes[result].depth = depth
  state.nodes[result].burst = false
  state.nodes[result].bucketCount = 0
  state.nodes[result].terminalCount = 0
  for symbol in 0..3: state.nodes[result].children[symbol] = -1

proc addToChild(state: var BurstState, node, stringId: int): bool

proc addString(state: var BurstState, node, stringId: int): bool =
  let depth = state.nodes[node].depth
  if state.lengths[stringId] == depth:
    let terminalCount = state.nodes[node].terminalCount
    if terminalCount >= MaxStrings: return false
    state.nodes[node].terminal[terminalCount] = stringId
    state.nodes[node].terminalCount = terminalCount + 1
    return true

  if state.nodes[node].burst:
    return addToChild(state, node, stringId)

  let bucketCount = state.nodes[node].bucketCount
  if bucketCount < BucketThreshold:
    state.nodes[node].bucket[bucketCount] = stringId
    state.nodes[node].bucketCount = bucketCount + 1
    return true

  var pending: array[MaxStrings, int]
  for index in 0..<bucketCount:
    pending[index] = state.nodes[node].bucket[index]
  state.nodes[node].bucketCount = 0
  state.nodes[node].burst = true
  for index in 0..<bucketCount:
    if not addToChild(state, node, pending[index]): return false
  return addToChild(state, node, stringId)

proc addToChild(state: var BurstState, node, stringId: int): bool =
  let depth = state.nodes[node].depth
  let symbol = state.bytes[stringId * MaxStringLength + depth]
  var child = state.nodes[node].children[symbol]
  if child < 0:
    child = newNode(state, depth + 1)
    if child < 0: return false
    state.nodes[node].children[symbol] = child
  return addString(state, child, stringId)

proc lessStrings(state: BurstState, left, right: int): bool =
  let commonLength = min(state.lengths[left], state.lengths[right])
  for index in 0..<commonLength:
    let leftByte = state.bytes[left * MaxStringLength + index]
    let rightByte = state.bytes[right * MaxStringLength + index]
    if leftByte != rightByte: return leftByte < rightByte
  return state.lengths[left] < state.lengths[right]

proc keyCode(state: BurstState, stringId: int): int64 =
  var code = 0'i64
  var weight = 78125'i64 # 5^(7-j), where j is the byte's index from the start.
  for index in 0..<state.lengths[stringId]:
    code += int64(state.bytes[stringId * MaxStringLength + index] + 1) * weight
    weight = weight div 5
  return code

proc emitNode(state: var BurstState, node: int, rank, checksum: var int64) =
  let terminalCount = state.nodes[node].terminalCount
  for index in 0..<terminalCount:
    inc rank
    checksum += rank * keyCode(state, state.nodes[node].terminal[index])

  if state.nodes[node].burst:
    for symbol in 0..3:
      let child = state.nodes[node].children[symbol]
      if child >= 0: emitNode(state, child, rank, checksum)
    return

  let bucketCount = state.nodes[node].bucketCount
  for position in 1..<bucketCount:
    let item = state.nodes[node].bucket[position]
    var insertion = position
    while insertion > 0 and lessStrings(state, item, state.nodes[node].bucket[insertion - 1]):
      state.nodes[node].bucket[insertion] = state.nodes[node].bucket[insertion - 1]
      dec insertion
    state.nodes[node].bucket[insertion] = item
  for index in 0..<bucketCount:
    inc rank
    checksum += rank * keyCode(state, state.nodes[node].bucket[index])

proc burstsort*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "burstsort".} =
  if input.isNil or length < 1 or length > csize_t(MaxInputWords): return -1
  let stringCountValue = input[0]
  if stringCountValue < 0 or stringCountValue > MaxStrings: return -1
  let stringCount = int(stringCountValue)
  var state: BurstState
  var inputPosition = 1
  for stringId in 0..<stringCount:
    if inputPosition >= int(length): return -1
    let stringLengthValue = input[inputPosition]
    inc inputPosition
    if stringLengthValue < 0 or stringLengthValue > MaxStringLength: return -1
    let stringLength = int(stringLengthValue)
    if stringLength > int(length) - inputPosition: return -1
    state.lengths[stringId] = stringLength
    for byteIndex in 0..<stringLength:
      let byteValue = input[inputPosition + byteIndex]
      if byteValue < 0 or byteValue > 3: return -1
      state.bytes[stringId * MaxStringLength + byteIndex] = int(byteValue)
    inputPosition += stringLength
  if inputPosition != int(length): return -1

  let root = newNode(state, 0)
  if root < 0: return -1
  for stringId in 0..<stringCount:
    if not addString(state, root, stringId): return -1
  var rank = 0'i64
  var checksum = 0'i64
  emitNode(state, root, rank, checksum)
  return checksum
