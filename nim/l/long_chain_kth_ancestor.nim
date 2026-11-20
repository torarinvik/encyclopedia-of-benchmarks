type LongChainAncestorState = object
  parent: array[64, int]
  depth: array[64, int]
  height: array[64, int]
  heavy: array[64, int]
  chainHead: array[64, int]
  chainPosition: array[64, int]
  chainBase: array[64, int]
  chainNodes: array[64, int]
  headAncestors: array[64, int]
  up: array[6, array[64, int]]

proc writeI64(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8((bits shr (8 * byte)) and 255)

proc long_chain_kth_ancestor*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "long_chain_kth_ancestor".} =
  if input.isNil or length < 2 or length > 130: return -1
  let nValue = input[0]
  let qValue = input[1]
  if nValue < 1 or nValue > 64 or qValue < 1 or qValue > 32: return -1
  let n = int(nValue)
  let q = int(qValue)
  if length != csize_t(n + 1 + 2 * q): return -1
  for vertex in 1 ..< n:
    if input[1 + vertex] < 0 or input[1 + vertex] >= int64(vertex): return -1
  let queryStart = n + 1
  for query in 0 ..< q:
    let vertex = input[queryStart + 2 * query]
    let distance = input[queryStart + 2 * query + 1]
    if vertex < 0 or vertex >= nValue or distance < 0 or distance >= 64: return -1
  let required = 8 * q
  if output.isNil or outputCapacity < csize_t(required): return -2

  var state: LongChainAncestorState
  state.parent[0] = -1
  for vertex in 0 ..< n:
    state.heavy[vertex] = -1
    state.chainHead[vertex] = -1
    state.chainBase[vertex] = -1
    state.height[vertex] = 1
    if vertex > 0:
      state.parent[vertex] = int(input[1 + vertex])
      state.depth[vertex] = state.depth[state.parent[vertex]] + 1
  for reverse in 1 ..< n:
    let vertex = n - 1 - (reverse - 1)
    let parent = state.parent[vertex]
    let old = state.heavy[parent]
    if old < 0 or state.height[vertex] > state.height[old] or
        (state.height[vertex] == state.height[old] and vertex < old):
      state.heavy[parent] = vertex
    state.height[parent] = max(state.height[parent], state.height[vertex] + 1)

  var pool = 0
  for vertex in 0 ..< n:
    if vertex == 0 or state.heavy[state.parent[vertex]] != vertex:
      state.chainBase[vertex] = pool
      var current = vertex
      var position = 0
      while current >= 0:
        state.chainHead[current] = vertex
        state.chainPosition[current] = position
        state.chainNodes[pool + position] = current
        current = state.heavy[current]
        inc position
      current = state.parent[vertex]
      for step in 0 ..< position:
        state.headAncestors[pool + step] = current
        current = if current >= 0: state.parent[current] else: -1
      pool += position
  for vertex in 0 ..< n: state.up[0][vertex] = state.parent[vertex]
  for level in 1 ..< 6:
    for vertex in 0 ..< n:
      let halfway = state.up[level - 1][vertex]
      state.up[level][vertex] = if halfway >= 0: state.up[level - 1][halfway] else: -1

  for query in 0 ..< q:
    let vertex = int(input[queryStart + 2 * query])
    let distance = int(input[queryStart + 2 * query + 1])
    var answer = -1
    if distance <= state.depth[vertex]:
      if distance == 0:
        answer = vertex
      else:
        var level = 0
        var value = distance
        while value > 1:
          inc level
          value = value shr 1
        let jumped = state.up[level][vertex]
        let remaining = distance - (1 shl level)
        let head = state.chainHead[jumped]
        let position = state.chainPosition[jumped]
        let base = state.chainBase[head]
        if remaining <= position:
          answer = state.chainNodes[base + position - remaining]
        else:
          let steps = remaining - position
          if steps <= state.height[head]: answer = state.headAncestors[base + steps - 1]
    writeI64(output, 8 * query, int64(answer))
  int64(required)
