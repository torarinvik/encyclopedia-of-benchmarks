const
  MaxQ = 128
  TreeBase = 128
  TreeHeight = 7
  MaxNodes = 1 + MaxQ * (TreeHeight + 1)
  MaxParseableInput = 1 + 3 * MaxQ + 1
  MaxValue = 1_000_000_000'i64

type Node = object
  left, right: int
  value: int64

proc setValue(nodes: var array[MaxNodes, Node], used: var int, root,
    low, high, position: int, value: int64): int =
  let copy = used
  inc used
  nodes[copy] = nodes[root]
  if high - low == 1:
    nodes[copy].value = value
    return copy
  let middle = low + (high - low) div 2
  if position < middle:
    let childRoot = nodes[root].left
    nodes[copy].left = setValue(nodes, used, childRoot, low, middle, position, value)
  else:
    let childRoot = nodes[root].right
    nodes[copy].right = setValue(nodes, used, childRoot, middle, high, position, value)
  copy

proc getValue(nodes: openArray[Node], root, low, high, position: int): int64 =
  if high - low == 1: return nodes[root].value
  let middle = low + (high - low) div 2
  if position < middle:
    getValue(nodes, nodes[root].left, low, middle, position)
  else:
    getValue(nodes, nodes[root].right, middle, high, position)

proc storeI64Le(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8((bits shr (8 * byte)) and 255)

proc persistent_queue*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "persistent_queue".} =
  if input.isNil or length < 1 or length > csize_t(MaxParseableInput): return -1
  let qValue = input[0]
  if qValue < 1 or qValue > MaxQ: return -1
  let q = int(qValue)
  var kind, parent, value: array[MaxQ, int64]
  var versionHead, versionTail, versionSize: array[MaxQ + 1, int]
  var cursor = 1
  var popCount = 0
  for operation in 0 ..< q:
    if cursor + 2 > int(length): return -1
    kind[operation] = input[cursor]
    inc cursor
    parent[operation] = input[cursor]
    inc cursor
    if (kind[operation] != 0 and kind[operation] != 1) or parent[operation] < -1 or
       parent[operation] >= int64(operation): return -1
    let base = int(parent[operation] + 1)
    if kind[operation] == 0:
      if cursor >= int(length): return -1
      value[operation] = input[cursor]
      inc cursor
      if value[operation] < 0 or value[operation] > MaxValue or versionTail[base] >= TreeBase:
        return -1
      versionHead[operation + 1] = versionHead[base]
      versionTail[operation + 1] = versionTail[base] + 1
      versionSize[operation + 1] = versionSize[base] + 1
    else:
      if versionSize[base] == 0: return -1
      versionHead[operation + 1] = versionHead[base] + 1
      versionTail[operation + 1] = versionTail[base]
      versionSize[operation + 1] = versionSize[base] - 1
      inc popCount
  if cursor != int(length): return -1
  let outputBytes = 8 * popCount
  if outputBytes > 0 and (output.isNil or capacity < csize_t(outputBytes)): return -2

  var nodes: array[MaxNodes, Node]
  var roots: array[MaxQ + 1, int]
  var answers: array[MaxQ, int64]
  var used = 1
  var answerCount = 0
  for operation in 0 ..< q:
    let base = int(parent[operation] + 1)
    let version = operation + 1
    if kind[operation] == 0:
      roots[version] = setValue(nodes, used, roots[base], 0, TreeBase,
                                versionTail[base], value[operation])
    else:
      answers[answerCount] = getValue(nodes, roots[base], 0, TreeBase,
                                      versionHead[base])
      inc answerCount
      roots[version] = roots[base]
  for index in 0 ..< answerCount:
    storeI64Le(output, index * 8, answers[index])
  int64(outputBytes)
