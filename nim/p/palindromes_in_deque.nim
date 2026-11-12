const MaxQueries = 32
const MaxNodes = MaxQueries + 2
const Alphabet = 26

type EertreeNode = object
  length: int
  link: int
  next: array[Alphabet, int]

proc extendable(nodes: var array[MaxNodes, EertreeNode],
                text: array[MaxQueries, int], position, start: int): int =
  var node = start
  while true:
    let preceding = position - nodes[node].length - 1
    if preceding >= 0 and text[preceding] == text[position]: return node
    node = nodes[node].link

proc storeI64Le(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8((bits shr (8 * byte)) and 255)

proc palindromes_in_deque*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "palindromes_in_deque".} =
  if input.isNil or length < 1 or length > csize_t(1 + 2 * MaxQueries): return -1
  let queryValue = input[0]
  if queryValue < 1 or queryValue > int64(MaxQueries): return -1
  let queries = int(queryValue)
  if length != csize_t(1 + 2 * queries): return -1

  var size = 0
  for query in 0 ..< queries:
    let operation = input[1 + 2 * query]
    let letter = input[2 + 2 * query]
    if operation == 0 or operation == 1:
      if letter < 0 or letter >= int64(Alphabet): return -1
      inc size
    elif operation == 2 or operation == 3:
      if letter != 0 or size == 0: return -1
      dec size
    else:
      return -1
  if output.isNil or capacity < csize_t(24 * queries): return -2

  var text: array[MaxQueries, int]
  size = 0
  for query in 0 ..< queries:
    let operation = int(input[1 + 2 * query])
    let letter = int(input[2 + 2 * query])
    if operation == 0:
      for index in countdown(size, 1): text[index] = text[index - 1]
      text[0] = letter
      inc size
    elif operation == 1:
      text[size] = letter
      inc size
    elif operation == 2:
      for index in 1 ..< size: text[index - 1] = text[index]
      dec size
    else:
      dec size

    var nodes: array[MaxNodes, EertreeNode]
    for node in 0 ..< MaxNodes:
      nodes[node].length = 0
      nodes[node].link = 0
      for letterIndex in 0 ..< Alphabet: nodes[node].next[letterIndex] = -1
    nodes[0].length = -1
    var nodeCount = 2
    var last = 1
    var longestPrefix = 0
    for position in 0 ..< size:
      let character = text[position]
      let parent = extendable(nodes, text, position, last)
      var child = nodes[parent].next[character]
      if child < 0:
        child = nodeCount
        inc nodeCount
        nodes[child].length = nodes[parent].length + 2
        if nodes[child].length == 1:
          nodes[child].link = 1
        else:
          let suffixParent = extendable(nodes, text, position, nodes[parent].link)
          nodes[child].link = nodes[suffixParent].next[character]
        nodes[parent].next[character] = child
      last = child
      if nodes[last].length == position + 1: longestPrefix = position + 1
    let offset = 24 * query
    storeI64Le(output, offset, int64(nodeCount - 2))
    storeI64Le(output, offset + 8, int64(longestPrefix))
    storeI64Le(output, offset + 16, int64(nodes[last].length))
  int64(24 * queries)
