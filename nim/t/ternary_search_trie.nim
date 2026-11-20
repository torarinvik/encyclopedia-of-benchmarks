const
  MaxOperations = 64
  MaxKeyLength = 6
  RecordWidth = 9
  MaxInputValues = 577
  MaxParseableInputValues = 578
  MaxNodes = 384

type
  TstNode = object
    character: int64
    left, middle, right: int
    value: int64
    present: bool

proc putNode(nodes: var array[MaxNodes + 1, TstNode], nodeIndex: int,
             key: ptr UncheckedArray[int64], length, depth: int, value: int64,
             oldValue: var int64, size, nodeCount: var int): int =
  var current = nodeIndex
  if current == 0:
    inc nodeCount
    current = nodeCount
    nodes[current].character = key[depth]
  if key[depth] < nodes[current].character:
    let child = putNode(nodes, nodes[current].left, key, length, depth, value,
                        oldValue, size, nodeCount)
    nodes[current].left = child
  elif key[depth] > nodes[current].character:
    let child = putNode(nodes, nodes[current].right, key, length, depth, value,
                        oldValue, size, nodeCount)
    nodes[current].right = child
  elif depth + 1 < length:
    let child = putNode(nodes, nodes[current].middle, key, length, depth + 1,
                        value, oldValue, size, nodeCount)
    nodes[current].middle = child
  else:
    oldValue = if nodes[current].present: nodes[current].value else: 0
    if not nodes[current].present: inc size
    nodes[current].value = value
    nodes[current].present = true
  current

proc findNode(nodes: openArray[TstNode], nodeIndex: int,
              key: ptr UncheckedArray[int64], length: int): int =
  var current = nodeIndex
  var depth = 0
  while current != 0:
    if key[depth] < nodes[current].character:
      current = nodes[current].left
    elif key[depth] > nodes[current].character:
      current = nodes[current].right
    elif depth + 1 == length:
      return current
    else:
      current = nodes[current].middle
      inc depth
  0

proc deleteNode(nodes: var array[MaxNodes + 1, TstNode], nodeIndex: int,
                key: ptr UncheckedArray[int64], length, depth: int,
                removed: var int64, size: var int): int =
  if nodeIndex == 0: return 0
  if key[depth] < nodes[nodeIndex].character:
    let child = deleteNode(nodes, nodes[nodeIndex].left, key, length, depth,
                           removed, size)
    nodes[nodeIndex].left = child
  elif key[depth] > nodes[nodeIndex].character:
    let child = deleteNode(nodes, nodes[nodeIndex].right, key, length, depth,
                           removed, size)
    nodes[nodeIndex].right = child
  elif depth + 1 < length:
    let child = deleteNode(nodes, nodes[nodeIndex].middle, key, length, depth + 1,
                           removed, size)
    nodes[nodeIndex].middle = child
  elif nodes[nodeIndex].present:
    removed = nodes[nodeIndex].value
    nodes[nodeIndex].value = 0
    nodes[nodeIndex].present = false
    dec size
  if not nodes[nodeIndex].present and nodes[nodeIndex].left == 0 and
     nodes[nodeIndex].middle == 0 and nodes[nodeIndex].right == 0: return 0
  nodeIndex

proc countNodes(nodes: openArray[TstNode], nodeIndex: int): int =
  if nodeIndex == 0: return 0
  ord(nodes[nodeIndex].present) + countNodes(nodes, nodes[nodeIndex].left) +
    countNodes(nodes, nodes[nodeIndex].middle) + countNodes(nodes, nodes[nodeIndex].right)

proc countMatches(nodes: openArray[TstNode], nodeIndex: int,
                  pattern: ptr UncheckedArray[int64], length, depth: int): int =
  if nodeIndex == 0: return 0
  let token = pattern[depth]
  if token == 46:
    let here = if depth + 1 == length: ord(nodes[nodeIndex].present)
               else: countMatches(nodes, nodes[nodeIndex].middle, pattern, length, depth + 1)
    return countMatches(nodes, nodes[nodeIndex].left, pattern, length, depth) + here +
      countMatches(nodes, nodes[nodeIndex].right, pattern, length, depth)
  if token < nodes[nodeIndex].character:
    return countMatches(nodes, nodes[nodeIndex].left, pattern, length, depth)
  if token > nodes[nodeIndex].character:
    return countMatches(nodes, nodes[nodeIndex].right, pattern, length, depth)
  if depth + 1 == length: return ord(nodes[nodeIndex].present)
  countMatches(nodes, nodes[nodeIndex].middle, pattern, length, depth + 1)

proc validInput(input: ptr UncheckedArray[int64], length: csize_t,
                operationCount: var int): bool =
  if input == nil or length < 1 or length > MaxParseableInputValues: return false
  if input[0] < 0 or input[0] > MaxOperations: return false
  operationCount = int(input[0])
  if length != csize_t(1 + operationCount * RecordWidth): return false
  for operation in 0 ..< operationCount:
    let base = 1 + operation * RecordWidth
    let opcode = input[base]
    let keyLength = input[base + 1]
    if opcode < 0 or opcode > 6 or keyLength < 0 or keyLength > MaxKeyLength: return false
    if (opcode <= 2 and keyLength == 0) or (opcode == 6 and keyLength != 0): return false
    for index in 0 ..< MaxKeyLength:
      let character = input[base + 2 + index]
      if index < int(keyLength):
        if not ((character >= 97 and character <= 122) or (opcode == 5 and character == 46)):
          return false
      elif character != 0: return false
    let value = input[base + RecordWidth - 1]
    if opcode == 0:
      if value < 1 or value > 65535: return false
    elif value != 0: return false
  true

proc ternary_search_trie*(input: ptr UncheckedArray[int64],
                          length: csize_t): int64 {.cdecl, exportc: "ternary_search_trie".} =
  var operationCount = 0
  if not validInput(input, length, operationCount): return -1
  var nodes: array[MaxNodes + 1, TstNode]
  var nodeCount = 0
  var root = 0
  var size = 0
  var total = 0'i64
  for operation in 0 ..< operationCount:
    let base = 1 + operation * RecordWidth
    let opcode = input[base]
    let keyLength = int(input[base + 1])
    let key = cast[ptr UncheckedArray[int64]](addr input[base + 2])
    let value = input[base + RecordWidth - 1]
    var observed = 0'i64
    if opcode == 0:
      root = putNode(nodes, root, key, keyLength, 0, value, observed, size, nodeCount)
    elif opcode == 1:
      let found = findNode(nodes, root, key, keyLength)
      if found != 0 and nodes[found].present: observed = nodes[found].value
    elif opcode == 2:
      root = deleteNode(nodes, root, key, keyLength, 0, observed, size)
    elif opcode == 3:
      var current = root
      var depth = 0
      while current != 0 and depth < keyLength:
        if key[depth] < nodes[current].character: current = nodes[current].left
        elif key[depth] > nodes[current].character: current = nodes[current].right
        else:
          inc depth
          if nodes[current].present: observed = int64(depth)
          current = nodes[current].middle
    elif opcode == 4:
      if keyLength == 0: observed = int64(size)
      else:
        let found = findNode(nodes, root, key, keyLength)
        if found != 0:
          observed = int64(ord(nodes[found].present) + countNodes(nodes, nodes[found].middle))
    elif opcode == 5 and keyLength != 0:
      observed = int64(countMatches(nodes, root, key, keyLength, 0))
    elif opcode == 6:
      observed = int64(size)
    total += int64(operation + 1) * observed
  total
