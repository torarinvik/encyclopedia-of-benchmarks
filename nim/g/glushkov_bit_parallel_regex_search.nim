type
  I64Input = ptr UncheckedArray[int64]
  U8Output = ptr UncheckedArray[uint8]
  RegexNode = object
    kind, left, right, position: int
  RegexParser = object
    pattern: I64Input
    length, cursor, nodeCount, positionCount: int
    nodes: array[64, RegexNode]
    symbols: array[9, uint8]
    failed: bool

const
  MaxText = 24
  MaxPattern = 32
  PositionNode = 1
  ConcatNode = 2
  AltNode = 3
  StarNode = 4

proc parseExpression(p: var RegexParser): int

proc addNode(p: var RegexParser, kind, left = 0, right = 0, position = 0): int =
  if p.nodeCount >= 64:
    p.failed = true
    return 0
  result = p.nodeCount
  p.nodes[result] = RegexNode(kind: kind, left: left, right: right, position: position)
  inc p.nodeCount

proc parseAtom(p: var RegexParser): int =
  if p.cursor >= p.length:
    p.failed = true
    return 0
  let token = p.pattern[p.cursor]
  inc p.cursor
  if token == 40:
    result = parseExpression(p)
    if p.failed or p.cursor >= p.length or p.pattern[p.cursor] != 41:
      p.failed = true
      return 0
    inc p.cursor
    return
  if token != 97 and token != 98 and token != 99 and token != 46:
    p.failed = true
    return 0
  if p.positionCount >= 8:
    p.failed = true
    return 0
  inc p.positionCount
  p.symbols[p.positionCount] = uint8(token)
  addNode(p, PositionNode, position = p.positionCount)

proc parseRepetition(p: var RegexParser): int =
  result = parseAtom(p)
  if not p.failed and p.cursor < p.length and p.pattern[p.cursor] == 42:
    inc p.cursor
    result = addNode(p, StarNode, result)

proc parseConcatenation(p: var RegexParser): int =
  if p.cursor >= p.length or p.pattern[p.cursor] == 124 or p.pattern[p.cursor] == 41:
    p.failed = true
    return 0
  result = parseRepetition(p)
  while not p.failed and p.cursor < p.length and p.pattern[p.cursor] != 124 and p.pattern[p.cursor] != 41:
    let right = parseRepetition(p)
    result = addNode(p, ConcatNode, result, right)

proc parseExpression(p: var RegexParser): int =
  result = parseConcatenation(p)
  while not p.failed and p.cursor < p.length and p.pattern[p.cursor] == 124:
    inc p.cursor
    let right = parseConcatenation(p)
    result = addNode(p, AltNode, result, right)

proc glushkov_bit_parallel_regex_search*(input: I64Input, length: csize_t,
    output: U8Output, outputCapacity: csize_t): int64 {.cdecl, exportc: "glushkov_bit_parallel_regex_search".} =
  if input == nil or length < 2 or length > 58: return -1
  if input[0] < 0 or input[0] > MaxText or input[1] < 1 or input[1] > MaxPattern: return -1
  let textLength = int(input[0])
  let patternLength = int(input[1])
  if length != csize_t(2 + textLength + patternLength): return -1
  for i in 0 ..< textLength + patternLength:
    if input[2 + i] < 1 or input[2 + i] > 127: return -1

  var parser = RegexParser(pattern: cast[I64Input](cast[uint](input) + uint((2 + textLength) * sizeof(int64))), length: patternLength)
  let root = parseExpression(parser)
  if parser.failed or parser.cursor != patternLength or parser.nodeCount == 0: return -1

  var nullable: array[64, bool]
  var first, last: array[64, uint16]
  var follow: array[9, uint16]
  for i in 0 ..< parser.nodeCount:
    let node = parser.nodes[i]
    if node.kind == PositionNode:
      let bit = uint16(1 shl node.position)
      first[i] = bit
      last[i] = bit
    elif node.kind == StarNode:
      nullable[i] = true
      first[i] = first[node.left]
      last[i] = last[node.left]
      for pos in 1 .. parser.positionCount:
        if (last[node.left] and uint16(1 shl pos)) != 0: follow[pos] = follow[pos] or first[node.left]
    elif node.kind == AltNode:
      nullable[i] = nullable[node.left] or nullable[node.right]
      first[i] = first[node.left] or first[node.right]
      last[i] = last[node.left] or last[node.right]
    else:
      nullable[i] = nullable[node.left] and nullable[node.right]
      first[i] = first[node.left] or (if nullable[node.left]: first[node.right] else: 0'u16)
      last[i] = last[node.right] or (if nullable[node.right]: last[node.left] else: 0'u16)
      for pos in 1 .. parser.positionCount:
        if (last[node.left] and uint16(1 shl pos)) != 0: follow[pos] = follow[pos] or first[node.right]
  follow[0] = first[root] or 1'u16

  var transitions: array[512, uint16]
  let subsetCount = 1 shl (parser.positionCount + 1)
  for subset in 1 ..< subsetCount:
    var state = 0
    while ((subset shr state) and 1) == 0: inc state
    transitions[subset] = transitions[subset and (subset - 1)] or follow[state]
  var byteMasks: array[128, uint16]
  for byte in 0 ..< 128: byteMasks[byte] = 1
  for pos in 1 .. parser.positionCount:
    for byte in 1 ..< 128:
      if parser.symbols[pos] == uint8(ord('.')) or int(parser.symbols[pos]) == byte:
        byteMasks[byte] = byteMasks[byte] or uint16(1 shl pos)
  var staged: array[MaxText, uint8]
  var active = 1'u16
  for i in 0 ..< textLength:
    active = transitions[int(active)] and byteMasks[int(input[2 + i])]
    staged[i] = if (active and last[root]) != 0: 1 else: 0
  if textLength > 0 and (output == nil or outputCapacity < csize_t(textLength)): return -2
  for i in 0 ..< textLength: output[i] = staged[i]
  int64(textLength)
