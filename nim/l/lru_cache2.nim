const MaxCapacity = 64
const MaxOperations = 256
const MapSize = 1024
const NilValue = low(int64)

type CacheNode = object
  key: int32
  value: int32
  previous: int
  next: int

type MapEntry = object
  key: int32
  node: int
  state: uint8

proc hashKey(key: int32): int =
  int((cast[uint32](key) *% 2654435761'u32) and uint32(MapSize - 1))

proc mapFind(map: var array[MapSize, MapEntry], key: int32): int =
  let start = hashKey(key)
  for probe in 0 ..< MapSize:
    let index = (start + probe) and (MapSize - 1)
    if map[index].state == 0: return -1
    if map[index].state == 1 and map[index].key == key: return map[index].node
  -1

proc mapInsert(map: var array[MapSize, MapEntry], key: int32, node: int): bool =
  let start = hashKey(key)
  var tombstone = -1
  for probe in 0 ..< MapSize:
    var index = (start + probe) and (MapSize - 1)
    if map[index].state == 1 and map[index].key == key: return false
    if map[index].state == 2 and tombstone < 0: tombstone = index
    if map[index].state == 0:
      if tombstone >= 0: index = tombstone
      map[index] = MapEntry(key: key, node: node, state: 1)
      return true
  if tombstone >= 0:
    map[tombstone] = MapEntry(key: key, node: node, state: 1)
    return true
  false

proc mapRemove(map: var array[MapSize, MapEntry], key: int32) =
  let start = hashKey(key)
  for probe in 0 ..< MapSize:
    let index = (start + probe) and (MapSize - 1)
    if map[index].state == 0: return
    if map[index].state == 1 and map[index].key == key:
      map[index].state = 2
      return

proc unlinkNode(nodes: var array[MaxCapacity, CacheNode], head, tail: var int, node: int) =
  let previous = nodes[node].previous
  let next = nodes[node].next
  if previous < 0: head = next else: nodes[previous].next = next
  if next < 0: tail = previous else: nodes[next].previous = previous

proc linkAtHead(nodes: var array[MaxCapacity, CacheNode], head, tail: var int, node: int) =
  nodes[node].previous = -1
  nodes[node].next = head
  if head < 0: tail = node else: nodes[head].previous = node
  head = node

proc promoteNode(nodes: var array[MaxCapacity, CacheNode], head, tail: var int, node: int) =
  if head == node: return
  unlinkNode(nodes, head, tail, node)
  linkAtHead(nodes, head, tail, node)

proc storeI64(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8: output[offset + byte] = uint8((bits shr (8 * byte)) and 255'u64)

proc lru_cache2*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "lru_cache2".} =
  if input.isNil or length < csize_t(2) or length > csize_t(771): return -1
  if input[0] < 2 or input[0] > 64 or input[1] < 0 or input[1] > 256: return -1
  let cacheCapacity = int(input[0])
  let operationCount = int(input[1])
  if int(length) != 2 + 3 * operationCount: return -1

  var nodes: array[MaxCapacity, CacheNode]
  var map: array[MapSize, MapEntry]
  var seenPutKeys: array[MaxOperations, int32]
  var seenCount = 0
  var head = -1
  var tail = -1
  var nodeCount = 0
  var results: array[MaxOperations, int64]

  for operation in 0 ..< operationCount:
    let base = 2 + operation * 3
    let opcode = input[base]
    let first = input[base + 1]
    let second = input[base + 2]
    if opcode < 0 or opcode > 4: return -1
    if opcode == 0:
      if first < int64(low(int32)) or first > int64(high(int32)) or second < int64(low(int32)) or second > int64(high(int32)): return -1
      let key = int32(first)
      for index in 0 ..< seenCount:
        if seenPutKeys[index] == key: return -1
      seenPutKeys[seenCount] = key
      inc seenCount
      var node: int
      if nodeCount < cacheCapacity:
        node = nodeCount
        inc nodeCount
      else:
        node = tail
        mapRemove(map, nodes[node].key)
        unlinkNode(nodes, head, tail, node)
      nodes[node].key = key
      nodes[node].value = int32(second)
      if not mapInsert(map, key, node): return -1
      linkAtHead(nodes, head, tail, node)
      results[operation] = NilValue
    elif opcode == 1:
      if first < int64(low(int32)) or first > int64(high(int32)) or second != 0: return -1
      let node = mapFind(map, int32(first))
      if node < 0: return -1
      promoteNode(nodes, head, tail, node)
      results[operation] = int64(nodes[node].value)
    else:
      if first != 0 or second != 0: return -1
      if opcode == 2: results[operation] = int64(nodeCount)
      elif opcode == 3: results[operation] = int64(cacheCapacity)
      else: results[operation] = if nodeCount == 0: 1 else: 0

  let outputBytes = operationCount * 8
  if output.isNil or outputCapacity < csize_t(outputBytes): return -2
  for operation in 0 ..< operationCount: storeI64(output, operation * 8, results[operation])
  int64(outputBytes)
