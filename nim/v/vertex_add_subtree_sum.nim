const
  MaxN = 128
  MaxQ = 256
  MaxInputValues = 2 * MaxN + 1 + 3 * MaxQ
  MaxValue = 1_000_000'i64

proc fenwickAdd(tree: var array[MaxN + 1, int64], n, position: int, delta: int64) =
  var index = position + 1
  while index <= n:
    tree[index] += delta
    index += index and -index

proc fenwickPrefix(tree: openArray[int64], count: int): int64 =
  var index = count
  while index > 0:
    result += tree[index]
    index -= index and -index

proc putI64Le(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8((bits shr (8 * byte)) and 255)

proc vertex_add_subtree_sum*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "vertex_add_subtree_sum".} =
  if input.isNil or length < 2 or length > csize_t(MaxInputValues): return -1
  let nValue = input[0]
  let qValue = input[1]
  if nValue < 1 or nValue > MaxN or qValue < 0 or qValue > MaxQ: return -1
  let n = int(nValue)
  let q = int(qValue)
  if length != csize_t(2 * n + 1 + 3 * q): return -1

  var values: array[MaxN, int64]
  var firstChild: array[MaxN, int64]
  var nextSibling: array[MaxN, int64]
  for vertex in 0 ..< MaxN:
    firstChild[vertex] = -1
    nextSibling[vertex] = -1
  for vertex in 0 ..< n:
    values[vertex] = input[2 + vertex]
    if values[vertex] < 0 or values[vertex] > MaxValue: return -1
  let parentStart = 2 + n
  for vertex in 1 ..< n:
    let parentValue = input[parentStart + vertex - 1]
    if parentValue < 0 or parentValue >= int64(vertex): return -1
    let parent = int(parentValue)
    nextSibling[vertex] = firstChild[parent]
    firstChild[parent] = int64(vertex)

  var tin, tout, stackNode: array[MaxN, int]
  var stackNextChild: array[MaxN, int64]
  var timer = 0
  var top = 1
  stackNode[0] = 0
  stackNextChild[0] = firstChild[0]
  tin[0] = timer
  inc timer
  while top > 0:
    let frame = top - 1
    let childValue = stackNextChild[frame]
    if childValue < 0:
      tout[stackNode[frame]] = timer
      dec top
      continue
    let child = int(childValue)
    stackNextChild[frame] = nextSibling[child]
    tin[child] = timer
    inc timer
    stackNode[top] = child
    stackNextChild[top] = firstChild[child]
    inc top

  var fenwick: array[MaxN + 1, int64]
  for vertex in 0 ..< n:
    fenwickAdd(fenwick, n, tin[vertex], values[vertex])
  var answers: array[MaxQ, int64]
  var answerCount = 0
  let operationStart = parentStart + n - 1
  for index in 0 ..< q:
    let offset = operationStart + 3 * index
    let kind = input[offset]
    let vertexValue = input[offset + 1]
    let operand = input[offset + 2]
    if kind == 0:
      if vertexValue < 0 or vertexValue >= nValue or operand < 0 or operand > MaxValue: return -1
      let vertex = int(vertexValue)
      values[vertex] += operand
      fenwickAdd(fenwick, n, tin[vertex], operand)
    elif kind == 1:
      if vertexValue < 0 or vertexValue >= nValue or operand != 0: return -1
      let vertex = int(vertexValue)
      answers[answerCount] = fenwickPrefix(fenwick, tout[vertex]) - fenwickPrefix(fenwick, tin[vertex])
      inc answerCount
    else:
      return -1

  let outputBytes = 8 * answerCount
  if outputBytes > 0 and (output.isNil or capacity < csize_t(outputBytes)): return -2
  for index in 0 ..< answerCount:
    putI64Le(output, 8 * index, answers[index])
  int64(outputBytes)
