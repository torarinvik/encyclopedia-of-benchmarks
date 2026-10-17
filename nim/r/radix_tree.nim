const MaxOperations = 256
const MaxWordLength = 32
const NodeCapacity = 1 + 2 * MaxOperations
const MaxValidInputLength = 1 + MaxOperations * (2 + MaxWordLength)
const MaxParseableInputLength = MaxValidInputLength + 1
const MaxPrefixLength = MaxOperations * MaxWordLength
const InvalidResult = -1'i64

type
  RadixNode = object
    prefix: array[MaxWordLength, uint8]
    prefixLength: int
    isLeaf: bool
    children: array[26, int]

proc prefixByte(nodes: var array[NodeCapacity, RadixNode],
                rootPrefix: var array[MaxPrefixLength, uint8], node, index: int): uint8 =
  if node == 0: rootPrefix[index]
  else: nodes[node].prefix[index]

proc prefixSet(nodes: var array[NodeCapacity, RadixNode],
               rootPrefix: var array[MaxPrefixLength, uint8], node, index: int, value: uint8) =
  if node == 0: rootPrefix[index] = value
  else: nodes[node].prefix[index] = value

proc childCount(nodes: var array[NodeCapacity, RadixNode], node: int, onlyChild: var int): int =
  var count = 0
  for letter in 0 ..< 26:
    if nodes[node].children[letter] != 0:
      onlyChild = nodes[node].children[letter] - 1
      inc count
  count

proc mergeNode(nodes: var array[NodeCapacity, RadixNode],
               rootPrefix: var array[MaxPrefixLength, uint8], destination, source: int): bool =
  let destinationLength = nodes[destination].prefixLength
  let sourceLength = nodes[source].prefixLength
  let combinedLength = destinationLength + sourceLength
  let limit = if destination == 0: MaxPrefixLength else: MaxWordLength
  if combinedLength > limit: return false
  for index in 0 ..< sourceLength:
    let byte = prefixByte(nodes, rootPrefix, source, index)
    prefixSet(nodes, rootPrefix, destination, destinationLength + index, byte)
  nodes[destination].prefixLength = combinedLength
  nodes[destination].isLeaf = nodes[source].isLeaf
  nodes[destination].children = nodes[source].children
  true

proc insert(nodes: var array[NodeCapacity, RadixNode],
            rootPrefix: var array[MaxPrefixLength, uint8], nextNode: var int,
            nodeIndex: int, word: array[MaxWordLength, uint8], start, length: int): bool =
  let remainingLength = length - start
  if remainingLength == 0:
    nodes[nodeIndex].isLeaf = true
    return true
  if nodes[nodeIndex].prefixLength == remainingLength and not nodes[nodeIndex].isLeaf:
    var index = 0
    while index < remainingLength and prefixByte(nodes, rootPrefix, nodeIndex, index) == word[start + index]:
      inc index
    if index == remainingLength:
      nodes[nodeIndex].isLeaf = true
      return true

  let letter = int(word[start] - uint8(ord('a')))
  let childPlusOne = nodes[nodeIndex].children[letter]
  if childPlusOne == 0:
    if nextNode >= NodeCapacity: return false
    let child = nextNode
    inc nextNode
    for index in 0 ..< remainingLength:
      prefixSet(nodes, rootPrefix, child, index, word[start + index])
    nodes[child].prefixLength = remainingLength
    nodes[child].isLeaf = true
    nodes[nodeIndex].children[letter] = child + 1
    return true

  let child = childPlusOne - 1
  var matched = 0
  while matched < nodes[child].prefixLength and matched < remainingLength and
        prefixByte(nodes, rootPrefix, child, matched) == word[start + matched]:
    inc matched
  let remainingPrefixLength = nodes[child].prefixLength - matched
  if remainingPrefixLength == 0:
    return insert(nodes, rootPrefix, nextNode, child, word, start + matched, length)
  if nextNode >= NodeCapacity: return false

  for index in 0 ..< remainingPrefixLength:
    let byte = prefixByte(nodes, rootPrefix, child, matched + index)
    prefixSet(nodes, rootPrefix, child, index, byte)
  nodes[child].prefixLength = remainingPrefixLength
  let middle = nextNode
  inc nextNode
  for index in 0 ..< matched:
    prefixSet(nodes, rootPrefix, middle, index, word[start + index])
  nodes[middle].prefixLength = matched
  let suffixLetter = int(prefixByte(nodes, rootPrefix, child, 0) - uint8(ord('a')))
  nodes[middle].children[suffixLetter] = child + 1
  nodes[nodeIndex].children[letter] = middle + 1
  if start + matched == length:
    nodes[middle].isLeaf = true
    return true
  insert(nodes, rootPrefix, nextNode, middle, word, start + matched, length)

proc find(nodes: var array[NodeCapacity, RadixNode],
          rootPrefix: var array[MaxPrefixLength, uint8], nodeIndex: int,
          word: array[MaxWordLength, uint8], start, length: int): bool =
  if start >= length: return nodes[nodeIndex].isLeaf
  let letter = int(word[start] - uint8(ord('a')))
  let childPlusOne = nodes[nodeIndex].children[letter]
  if childPlusOne == 0: return false
  let child = childPlusOne - 1
  var matched = 0
  while matched < nodes[child].prefixLength and start + matched < length and
        prefixByte(nodes, rootPrefix, child, matched) == word[start + matched]:
    inc matched
  if matched != nodes[child].prefixLength: return false
  let nextStart = start + matched
  if nextStart == length: return nodes[child].isLeaf
  find(nodes, rootPrefix, child, word, nextStart, length)

proc remove(nodes: var array[NodeCapacity, RadixNode],
             rootPrefix: var array[MaxPrefixLength, uint8], nodeIndex: int,
             word: array[MaxWordLength, uint8], start, length: int): int =
  if start >= length: return 0
  let letter = int(word[start] - uint8(ord('a')))
  let childPlusOne = nodes[nodeIndex].children[letter]
  if childPlusOne == 0: return 0
  let child = childPlusOne - 1
  var matched = 0
  while matched < nodes[child].prefixLength and start + matched < length and
        prefixByte(nodes, rootPrefix, child, matched) == word[start + matched]:
    inc matched
  if matched != nodes[child].prefixLength: return 0
  let nextStart = start + matched
  if nextStart < length: return remove(nodes, rootPrefix, child, word, nextStart, length)
  if not nodes[child].isLeaf: return 0

  var onlyChild = 0
  let children = childCount(nodes, child, onlyChild)
  if children == 0:
    nodes[nodeIndex].children[letter] = 0
    var survivor = 0
    if not nodes[nodeIndex].isLeaf and childCount(nodes, nodeIndex, survivor) == 1:
      if mergeNode(nodes, rootPrefix, nodeIndex, survivor): return 1
      return -1
  elif children > 1:
    nodes[child].isLeaf = false
  else:
    if mergeNode(nodes, rootPrefix, child, onlyChild): return 1
    return -1
  1

proc radix_tree_benchmark*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "radix_tree_benchmark".} =
  if input.isNil or length < csize_t(1) or length > csize_t(MaxParseableInputLength): return InvalidResult
  if input[0] < 0 or input[0] > int64(MaxOperations): return InvalidResult
  let operationCount = int(input[0])
  var nodes: array[NodeCapacity, RadixNode]
  var rootPrefix: array[MaxPrefixLength, uint8]
  var nextNode = 1
  var offset = 1
  var checksum = 0'i64

  for operation in 0 ..< operationCount:
    if offset + 2 > int(length): return InvalidResult
    let opcode = input[offset]
    let wordLengthValue = input[offset + 1]
    offset += 2
    if opcode < 0 or opcode > 2 or wordLengthValue < 1 or wordLengthValue > int64(MaxWordLength): return InvalidResult
    let wordLength = int(wordLengthValue)
    if wordLength > int(length) - offset: return InvalidResult
    var word: array[MaxWordLength, uint8]
    for index in 0 ..< wordLength:
      let byte = input[offset + index]
      if byte < 97'i64 or byte > 122'i64: return InvalidResult
      word[index] = uint8(byte)
    offset += wordLength

    if opcode == 0:
      if not insert(nodes, rootPrefix, nextNode, 0, word, 0, wordLength): return InvalidResult
    else:
      var observed = 0
      if opcode == 1:
        if find(nodes, rootPrefix, 0, word, 0, wordLength): observed = 1
      else:
        observed = remove(nodes, rootPrefix, 0, word, 0, wordLength)
      if observed < 0: return InvalidResult
      checksum += int64(operation + 1) * int64(1 + observed)
  if offset != int(length): return InvalidResult
  checksum
