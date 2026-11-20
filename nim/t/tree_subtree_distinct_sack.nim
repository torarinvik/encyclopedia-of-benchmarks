type SackState = object
  n: int
  parent: array[64, int]
  firstChild: array[64, int]
  nextSibling: array[64, int]
  order: array[64, int]
  tin: array[64, int]
  subtreeSize: array[64, int]
  heavy: array[64, int]
  frequency: array[256, int]
  answer: array[64, int]
  distinct: int
  frameVertex: array[64, int]
  frameKeep: array[64, bool]
  frameStage: array[64, int]
  frameChild: array[64, int]

proc addInterval(state: var SackState, colors: array[64, int], begin, count, delta: int) =
  for position in begin ..< begin + count:
    let color = colors[state.order[position]]
    if delta > 0:
      if state.frequency[color] == 0: inc state.distinct
      inc state.frequency[color]
    else:
      dec state.frequency[color]
      if state.frequency[color] == 0: dec state.distinct

proc solveSack(state: var SackState, colors: array[64, int]) =
  var stackNext: array[64, int]
  var depth = 1
  var timer = 1
  state.order[0] = 0
  state.tin[0] = 0
  stackNext[0] = state.firstChild[0]
  while depth > 0:
    let frame = depth - 1
    let child = stackNext[frame]
    if child >= 0:
      stackNext[frame] = state.nextSibling[child]
      state.tin[child] = timer
      state.order[timer] = child
      inc timer
      stackNext[depth] = state.firstChild[child]
      inc depth
    else:
      dec depth

  for vertex in 0 ..< state.n:
    state.subtreeSize[vertex] = 1
    state.heavy[vertex] = -1
  for reverse in 0 ..< (state.n - 1):
    let position = state.n - 1 - reverse
    let vertex = state.order[position]
    let parent = state.parent[vertex]
    state.subtreeSize[parent] += state.subtreeSize[vertex]
    let oldHeavy = state.heavy[parent]
    if oldHeavy < 0 or state.subtreeSize[vertex] > state.subtreeSize[oldHeavy]:
      state.heavy[parent] = vertex

  var frameCount = 1
  state.frameVertex[0] = 0
  state.frameKeep[0] = false
  state.frameStage[0] = 0
  state.frameChild[0] = state.firstChild[0]
  while frameCount > 0:
    let frame = frameCount - 1
    let vertex = state.frameVertex[frame]
    if state.frameStage[frame] == 0:
      var child = state.frameChild[frame]
      while child >= 0 and child == state.heavy[vertex]:
        child = state.nextSibling[child]
      if child >= 0:
        state.frameChild[frame] = state.nextSibling[child]
        state.frameVertex[frameCount] = child
        state.frameKeep[frameCount] = false
        state.frameStage[frameCount] = 0
        state.frameChild[frameCount] = state.firstChild[child]
        inc frameCount
      else:
        state.frameStage[frame] = 1
    elif state.frameStage[frame] == 1:
      state.frameStage[frame] = 2
      let child = state.heavy[vertex]
      if child >= 0:
        state.frameVertex[frameCount] = child
        state.frameKeep[frameCount] = true
        state.frameStage[frameCount] = 0
        state.frameChild[frameCount] = state.firstChild[child]
        inc frameCount
    else:
      var child = state.firstChild[vertex]
      while child >= 0:
        if child != state.heavy[vertex]:
          addInterval(state, colors, state.tin[child], state.subtreeSize[child], 1)
        child = state.nextSibling[child]
      let color = colors[vertex]
      if state.frequency[color] == 0: inc state.distinct
      inc state.frequency[color]
      state.answer[vertex] = state.distinct
      if not state.frameKeep[frame]:
        addInterval(state, colors, state.tin[vertex], state.subtreeSize[vertex], -1)
      dec frameCount

proc writeI64(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8((bits shr (8 * byte)) and 255)

proc tree_subtree_distinct_sack*(input: ptr UncheckedArray[int64], length: csize_t,
                                 output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "tree_subtree_distinct_sack".} =
  if input.isNil or length < 2 or length > 130: return -1
  let nValue = input[0]
  if nValue < 1 or nValue > 64 or length != csize_t(2 * nValue): return -1
  let n = int(nValue)
  for vertex in 1 ..< n:
    if input[vertex] < 0 or input[vertex] >= int64(vertex): return -1
  var colors: array[64, int]
  for vertex in 0 ..< n:
    let color = input[n + vertex]
    if color < 0 or color > 255: return -1
    colors[vertex] = int(color)
  let required = 8 * n
  if output.isNil or outputCapacity < csize_t(required): return -2

  var state: SackState
  state.n = n
  for vertex in 0 ..< n: state.firstChild[vertex] = -1
  for vertex in 1 ..< n:
    let parent = int(input[vertex])
    state.parent[vertex] = parent
    state.nextSibling[vertex] = state.firstChild[parent]
    state.firstChild[parent] = vertex
  solveSack(state, colors)
  for vertex in 0 ..< n:
    writeI64(output, 8 * vertex, int64(state.answer[vertex]))
  int64(required)
