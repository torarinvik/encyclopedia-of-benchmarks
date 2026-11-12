const MaxQ = 64
const MaxBits = 30
const MaxNodes = 1 + MaxBits * MaxQ
const MaxInputValues = 1 + 2 * MaxQ
const ValueLimit = 1'i64 shl MaxBits

type BinaryTrie = object
  children: array[MaxNodes, array[2, int32]]
  count: array[MaxNodes, int32]
  nodeCount: int

proc findOrCreateChild(trie: var BinaryTrie, node, direction: int): int =
  var child = trie.children[node][direction]
  if child < 0:
    child = int32(trie.nodeCount)
    inc trie.nodeCount
    trie.children[int(child)] = [-1'i32, -1'i32]
    trie.children[node][direction] = child
  int(child)

proc insert(trie: var BinaryTrie, value: uint32) =
  var path: array[MaxBits + 1, int]
  var node = 0
  for depth in 0 ..< MaxBits:
    let bit = MaxBits - 1 - depth
    node = findOrCreateChild(trie, node, int((value shr bit) and 1))
    path[depth + 1] = node
  if trie.count[node] != 0: return
  for item in path: inc trie.count[item]

proc remove(trie: var BinaryTrie, value: uint32) =
  var path: array[MaxBits + 1, int]
  var node = 0
  for depth in 0 ..< MaxBits:
    let bit = MaxBits - 1 - depth
    let child = trie.children[node][int((value shr bit) and 1)]
    if child < 0: return
    node = int(child)
    path[depth + 1] = node
  if trie.count[node] == 0: return
  for item in path: dec trie.count[item]

proc minimumXor(trie: BinaryTrie, value: uint32): uint32 =
  var node = 0
  for bit in countdown(MaxBits - 1, 0):
    let preferred = int((value shr bit) and 1)
    let child = trie.children[node][preferred]
    if child >= 0 and trie.count[int(child)] > 0:
      node = int(child)
    else:
      result = result or (1'u32 shl bit)
      node = int(trie.children[node][preferred xor 1])

proc storeI64Le(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8((bits shr (8 * byte)) and 255)

proc set_xor_min*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "set_xor_min".} =
  if input.isNil or length < 3 or length > csize_t(MaxInputValues): return -1
  let qValue = input[0]
  if qValue < 1 or qValue > MaxQ: return -1
  let q = int(qValue)
  if length != csize_t(1 + 2 * q): return -1
  for operation in 0 ..< q:
    let offset = 1 + 2 * operation
    if input[offset] < 0 or input[offset] > 2 or input[offset + 1] < 0 or
       input[offset + 1] >= ValueLimit: return -1

  var trie: BinaryTrie
  for node in 0 ..< MaxNodes:
    trie.children[node] = [-1'i32, -1'i32]
  trie.nodeCount = 1
  var answers: array[MaxQ, int64]
  var answerCount = 0
  for operation in 0 ..< q:
    let offset = 1 + 2 * operation
    let kind = input[offset]
    let value = uint32(input[offset + 1])
    if kind == 0:
      trie.insert(value)
    elif kind == 1:
      trie.remove(value)
    else:
      if trie.count[0] == 0: return -1
      answers[answerCount] = int64(trie.minimumXor(value))
      inc answerCount

  let required = 8 * answerCount
  if output.isNil or capacity < csize_t(required): return -2
  for index in 0 ..< answerCount:
    storeI64Le(output, 8 * index, answers[index])
  int64(required)
