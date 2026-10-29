const
  MaxVertexCount = 63
  MaxEdgeCount = 2047
  MaxInputLength = 3 + 2 * MaxEdgeCount

proc countBits(value: uint64): int =
  var remaining = value
  while remaining != 0'u64:
    remaining = remaining and (remaining - 1'u64)
    inc result

proc dominator_tree*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "dominator_tree".} =
  if input.isNil or length < 3 or length > MaxInputLength.csize_t: return -1
  if input[0] < 1'i64 or input[0] > MaxVertexCount or input[1] < 0'i64 or
      input[1] >= input[0] or input[2] < 0'i64 or input[2] > MaxEdgeCount: return -1
  let vertexCount = int(input[0])
  let root = int(input[1])
  let edgeCount = int(input[2])
  if int(length) != 3 + 2 * edgeCount: return -1

  var outgoing: array[MaxVertexCount, uint64]
  for edge in 0 ..< edgeCount:
    let fromValue = input[3 + 2 * edge]
    let toValue = input[4 + 2 * edge]
    if fromValue < 0'i64 or toValue < 0'i64 or fromValue >= int64(vertexCount) or
        toValue >= int64(vertexCount): return -1
    outgoing[int(fromValue)] = outgoing[int(fromValue)] or (1'u64 shl int(toValue))

  var reachable = 1'u64 shl root
  var frontier = reachable
  while frontier != 0'u64:
    var discovered = 0'u64
    for vertex in 0 ..< vertexCount:
      if (frontier and (1'u64 shl vertex)) != 0'u64: discovered = discovered or outgoing[vertex]
    discovered = discovered and not reachable
    reachable = reachable or discovered
    frontier = discovered

  var dominators: array[MaxVertexCount, uint64]
  dominators[root] = 1'u64 shl root
  for vertex in 0 ..< vertexCount:
    if (reachable and (1'u64 shl vertex)) != 0'u64 and vertex != root:
      dominators[vertex] = reachable

  var changed = true
  while changed:
    changed = false
    for vertex in 0 ..< vertexCount:
      let vertexBit = 1'u64 shl vertex
      if (reachable and vertexBit) == 0'u64 or vertex == root: continue
      var common = reachable
      for predecessor in 0 ..< vertexCount:
        if (reachable and (1'u64 shl predecessor)) != 0'u64 and
            (outgoing[predecessor] and vertexBit) != 0'u64:
          common = common and dominators[predecessor]
      let updated = common or vertexBit
      if updated != dominators[vertex]:
        dominators[vertex] = updated
        changed = true

  if output.isNil or outputCapacity < csize_t(vertexCount): return -2
  for vertex in 0 ..< vertexCount:
    let vertexBit = 1'u64 shl vertex
    if (reachable and vertexBit) == 0'u64:
      output[vertex] = 255'u8
    elif vertex == root:
      output[vertex] = uint8(root)
    else:
      let strict = dominators[vertex] and not vertexBit
      var best = root
      var bestDepth = 0
      for candidate in 0 ..< vertexCount:
        if (strict and (1'u64 shl candidate)) == 0'u64: continue
        let depth = countBits(dominators[candidate])
        if depth > bestDepth:
          best = candidate
          bestDepth = depth
      output[vertex] = uint8(best)
  int64(vertexCount)
