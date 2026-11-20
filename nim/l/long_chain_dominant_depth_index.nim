type LongChainState = object
  parent: array[64, int]
  firstChild: array[64, int]
  nextSibling: array[64, int]
  height: array[64, int]
  heavy: array[64, int]
  base: array[64, int]
  count: array[64, int]
  dominantDepth: array[64, int]

proc writeI64(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8((bits shr (8 * byte)) and 255)

proc long_chain_dominant_depth_index*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "long_chain_dominant_depth_index".} =
  if input.isNil or length == 0 or length > 65: return -1
  let nValue = input[0]
  if nValue < 1 or nValue > 64 or length != csize_t(nValue): return -1
  let n = int(nValue)
  for vertex in 1 ..< n:
    if input[vertex] < 0 or input[vertex] >= int64(vertex): return -1
  let required = 8 * n
  if output.isNil or outputCapacity < csize_t(required): return -2

  var state: LongChainState
  for vertex in 0 ..< n:
    state.firstChild[vertex] = -1
    state.heavy[vertex] = -1
    state.height[vertex] = 1
  state.parent[0] = -1
  for vertex in 1 ..< n:
    let parent = int(input[vertex])
    state.parent[vertex] = parent
    state.nextSibling[vertex] = state.firstChild[parent]
    state.firstChild[parent] = vertex

  for reverse in 0 ..< n:
    let vertex = n - 1 - reverse
    var child = state.firstChild[vertex]
    var maximumHeight = 0
    while child >= 0:
      let childHeight = state.height[child]
      if childHeight > maximumHeight or
          (childHeight == maximumHeight and child < state.heavy[vertex]):
        maximumHeight = childHeight
        state.heavy[vertex] = child
      child = state.nextSibling[child]
    state.height[vertex] = maximumHeight + 1

  var poolSize = 0
  for vertex in 0 ..< n:
    if vertex == 0 or state.heavy[state.parent[vertex]] != vertex:
      var current = vertex
      while current >= 0:
        state.base[current] = poolSize
        inc poolSize
        current = state.heavy[current]

  for reverse in 0 ..< n:
    let vertex = n - 1 - reverse
    state.count[state.base[vertex]] = 1
    var bestDepth = 0
    var bestCount = 1
    let heavy = state.heavy[vertex]
    if heavy >= 0:
      bestDepth = state.dominantDepth[heavy] + 1
      bestCount = state.count[state.base[vertex] + bestDepth]
    var child = state.firstChild[vertex]
    while child >= 0:
      if child != heavy:
        for childDepth in 0 ..< state.height[child]:
          let depth = childDepth + 1
          let slot = state.base[vertex] + depth
          let count = state.count[slot] + state.count[state.base[child] + childDepth]
          state.count[slot] = count
          if count > bestCount or (count == bestCount and depth < bestDepth):
            bestCount = count
            bestDepth = depth
      child = state.nextSibling[child]
    state.dominantDepth[vertex] = bestDepth
  for vertex in 0 ..< n:
    writeI64(output, 8 * vertex, int64(state.dominantDepth[vertex]))
  int64(required)
