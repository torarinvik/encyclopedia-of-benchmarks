const MaxPattern = 16
const MaxText = 32
const MaxInput = 51
const MaxNodes = 32
const MaxStates = 8
const MaxEdges = 32

type
  NodeKind = enum nkEmpty, nkLiteral, nkConcat, nkUnion, nkStar
  Node = object
    kind: NodeKind
    value: uint8
    left, right: int
  Parser = object
    pattern: array[MaxPattern, uint8]
    length, position, nodeCount, fragments: int
    nodes: array[MaxNodes, Node]
  Edge = object
    source, target: int
    label: uint8
  Nfa = object
    stateCount, edgeCount: int
    edges: array[MaxEdges, Edge]
  Fragment = object
    start, accept: int
    valid: bool

proc addNode(parser: var Parser, kind: NodeKind, value: uint8,
    left, right: int): int =
  if parser.nodeCount >= MaxNodes: return -1
  result = parser.nodeCount
  parser.nodes[result] = Node(kind: kind, value: value, left: left, right: right)
  inc parser.nodeCount
  if kind in {nkLiteral, nkUnion, nkStar}: inc parser.fragments

proc peek(parser: Parser): int =
  if parser.position < parser.length: int(parser.pattern[parser.position]) else: -1

proc parseUnion(parser: var Parser): int
proc parseConcat(parser: var Parser): int
proc parseRepeat(parser: var Parser): int
proc parseAtom(parser: var Parser): int

proc parseUnion(parser: var Parser): int =
  result = parseConcat(parser)
  if result < 0: return
  while peek(parser) == ord('|'):
    inc parser.position
    let right = parseConcat(parser)
    if right < 0: return -1
    result = addNode(parser, nkUnion, 0, result, right)
    if result < 0: return

proc parseConcat(parser: var Parser): int =
  if peek(parser) < 0 or peek(parser) == ord(')') or peek(parser) == ord('|'):
    return -1
  result = parseRepeat(parser)
  if result < 0: return
  while peek(parser) >= 0 and peek(parser) != ord(')') and peek(parser) != ord('|'):
    let right = parseRepeat(parser)
    if right < 0: return -1
    result = addNode(parser, nkConcat, 0, result, right)
    if result < 0: return

proc parseRepeat(parser: var Parser): int =
  result = parseAtom(parser)
  if result < 0: return
  if peek(parser) == ord('*'):
    inc parser.position
    result = addNode(parser, nkStar, 0, result, 0)

proc parseAtom(parser: var Parser): int =
  let token = peek(parser)
  if token in [ord('a'), ord('b'), ord('c')]:
    inc parser.position
    return addNode(parser, nkLiteral, uint8(token), 0, 0)
  if token == ord('('):
    inc parser.position
    result = parseUnion(parser)
    if result < 0 or peek(parser) != ord(')'): return -1
    inc parser.position
    return
  -1

proc sourceCompatible(source: openArray[uint8]): bool =
  if source.len <= 1: return true
  if source[0] == uint8(ord('(')) and source[^1] == uint8(ord(')')):
    var depth = 0
    for index, token in source:
      if token == uint8(ord('(')): inc depth
      elif token == uint8(ord(')')): dec depth
      if depth == 0 and index + 1 < source.len: return false
    if depth != 0: return false
    return sourceCompatible(source[1 ..< source.len - 1])
  for operator in [uint8(ord('|')), 10'u8]:
    var depth = 0
    for index, token in source:
      if depth == 0 and token == operator:
        return sourceCompatible(source[0 ..< index]) and
          sourceCompatible(source[index + 1 .. ^1])
      if token == uint8(ord('(')): inc depth
      elif token == uint8(ord(')')): dec depth
  source[^1] == uint8(ord('*')) and sourceCompatible(source[0 ..< source.len - 1])

proc sourceCompatiblePattern(pattern: openArray[uint8]): bool =
  var processed: array[2 * MaxPattern, uint8]
  var length = 0
  for index, token in pattern:
    processed[length] = token
    inc length
    if index + 1 >= pattern.len: continue
    let following = pattern[index + 1]
    let tokenLiteral = token notin [uint8(ord('(')), uint8(ord(')')), uint8(ord('*')), uint8(ord('|'))]
    let nextLiteral = following notin [uint8(ord('(')), uint8(ord(')')), uint8(ord('*')), uint8(ord('|'))]
    if (tokenLiteral and nextLiteral) or (tokenLiteral and following == uint8(ord('('))) or
        (token == uint8(ord(')')) and following == uint8(ord('('))) or
        (token == uint8(ord(')')) and nextLiteral) or
        (token == uint8(ord('*')) and nextLiteral) or
        (token == uint8(ord('*')) and following == uint8(ord('('))):
      processed[length] = 10
      inc length
  sourceCompatible(processed.toOpenArray(0, length - 1))

proc addState(nfa: var Nfa): int =
  if nfa.stateCount >= MaxStates: return -1
  result = nfa.stateCount
  inc nfa.stateCount

proc addEdge(nfa: var Nfa, source, target: int, label: uint8): bool =
  if nfa.edgeCount >= MaxEdges: return false
  nfa.edges[nfa.edgeCount] = Edge(source: source, target: target, label: label)
  inc nfa.edgeCount
  true

proc compileNode(index: int, nodes: array[MaxNodes, Node], nfa: var Nfa): Fragment =
  let node = nodes[index]
  case node.kind
  of nkEmpty, nkLiteral:
    let start = addState(nfa)
    let accept = addState(nfa)
    if start < 0 or accept < 0: return Fragment(valid: false)
    let label = if node.kind == nkEmpty: 0'u8 else: node.value
    if not addEdge(nfa, start, accept, label): return Fragment(valid: false)
    Fragment(start: start, accept: accept, valid: true)
  of nkConcat:
    let left = compileNode(node.left, nodes, nfa)
    if not left.valid: return left
    let right = compileNode(node.right, nodes, nfa)
    if not right.valid or not addEdge(nfa, left.accept, right.start, 0):
      return Fragment(valid: false)
    Fragment(start: left.start, accept: right.accept, valid: true)
  of nkUnion:
    let left = compileNode(node.left, nodes, nfa)
    if not left.valid: return left
    let right = compileNode(node.right, nodes, nfa)
    if not right.valid: return right
    let start = addState(nfa)
    let accept = addState(nfa)
    if start < 0 or accept < 0: return Fragment(valid: false)
    if not addEdge(nfa, start, left.start, 0) or not addEdge(nfa, start, right.start, 0) or
        not addEdge(nfa, left.accept, accept, 0) or not addEdge(nfa, right.accept, accept, 0):
      return Fragment(valid: false)
    Fragment(start: start, accept: accept, valid: true)
  of nkStar:
    let child = compileNode(node.left, nodes, nfa)
    if not child.valid: return child
    let start = addState(nfa)
    let accept = addState(nfa)
    if start < 0 or accept < 0: return Fragment(valid: false)
    if not addEdge(nfa, start, child.start, 0) or not addEdge(nfa, start, accept, 0) or
        not addEdge(nfa, child.accept, child.start, 0) or not addEdge(nfa, child.accept, accept, 0):
      return Fragment(valid: false)
    Fragment(start: start, accept: accept, valid: true)

proc epsilonClosure(states: uint16, nfa: Nfa): uint16 =
  result = states
  var changed = true
  while changed:
    changed = false
    for edge in nfa.edges.toOpenArray(0, nfa.edgeCount - 1):
      if edge.label == 0 and (result and (1'u16 shl edge.source)) != 0:
        let target = 1'u16 shl edge.target
        if (result and target) == 0:
          result = result or target
          changed = true

proc mcnaughton_yamada_thompson*(input: ptr UncheckedArray[int64], inputLength: csize_t): int64
    {.cdecl, exportc: "mcnaughton_yamada_thompson".} =
  if input == nil or inputLength < 2 or inputLength > MaxInput.csize_t: return -1
  let patternLengthValue = input[0]
  let textLengthValue = input[1]
  if patternLengthValue < 0 or patternLengthValue > MaxPattern.int64 or
      textLengthValue < 0 or textLengthValue > MaxText.int64: return -1
  let patternLength = int(patternLengthValue)
  let textLength = int(textLengthValue)
  if inputLength != csize_t(2 + patternLength + textLength): return -1

  var pattern: array[MaxPattern, uint8]
  for index in 0 ..< patternLength:
    let value = input[2 + index]
    if value notin [97'i64, 98, 99, 40, 41, 42, 124]: return -1
    pattern[index] = uint8(value)
  for index in 0 ..< textLength:
    let value = input[2 + patternLength + index]
    if value < 1 or value > 127: return -1
  if patternLength > 0 and not sourceCompatiblePattern(pattern.toOpenArray(0, patternLength - 1)):
    return -1

  var parser = Parser(pattern: pattern, length: patternLength)
  var root: int
  if patternLength == 0:
    root = addNode(parser, nkEmpty, 0, 0, 0)
  else:
    root = parseUnion(parser)
  if root < 0 or parser.position != patternLength or parser.fragments > 4: return -1

  var nfa: Nfa
  let fragment = compileNode(root, parser.nodes, nfa)
  if not fragment.valid: return -1
  var active = epsilonClosure(1'u16 shl fragment.start, nfa)
  for index in 0 ..< textLength:
    let symbol = uint8(input[2 + patternLength + index])
    var next: uint16 = 0
    for edge in nfa.edges.toOpenArray(0, nfa.edgeCount - 1):
      if edge.label == symbol and (active and (1'u16 shl edge.source)) != 0:
        next = next or (1'u16 shl edge.target)
    active = epsilonClosure(next, nfa)
  if (active and (1'u16 shl fragment.accept)) != 0: 1 else: 0
