const MaxVertices = 16
const MaxInputLength = 246

proc lovaszTogglePopcount(value: uint64): int =
  var bits = value
  var count = 0
  while bits != 0'u64:
    bits = bits and (bits - 1'u64)
    inc count
  count

proc lovasz_toggle_defective_coloring_trace*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "lovasz_toggle_defective_coloring_trace".} =
  if input.isNil or length < 5 or length > csize_t(MaxInputLength): return -1
  let nValue = input[0]
  let redLimitValue = input[1]
  let blueLimitValue = input[2]
  let initialMaskValue = input[3]
  let edgeCountValue = input[4]
  if nValue < 0 or nValue > MaxVertices: return -1
  if redLimitValue < 1 or redLimitValue > 8 or blueLimitValue < 1 or blueLimitValue > 8: return -1
  let n = int(nValue)
  if edgeCountValue < 0 or edgeCountValue > int64(n * (n - 1) div 2): return -1
  let edgeCount = int(edgeCountValue)
  if length != csize_t(5 + 2 * edgeCount): return -1
  if initialMaskValue < 0: return -1
  let vertexMask = (1'u64 shl n) - 1'u64
  let initialMask = uint64(initialMaskValue)
  if (initialMask and not vertexMask) != 0'u64: return -1

  var adjacency: array[MaxVertices, uint64]
  for edge in 0 ..< edgeCount:
    let uValue = input[5 + 2 * edge]
    let vValue = input[6 + 2 * edge]
    if uValue < 0 or vValue <= uValue or vValue >= nValue: return -1
    let u = int(uValue)
    let v = int(vValue)
    let uBit = 1'u64 shl u
    let vBit = 1'u64 shl v
    if (adjacency[u] and vBit) != 0'u64: return -1
    adjacency[u] = adjacency[u] or vBit
    adjacency[v] = adjacency[v] or uBit
  let maximumDegree = int(redLimitValue + blueLimitValue + 1)
  for vertex in 0 ..< n:
    if lovaszTogglePopcount(adjacency[vertex]) > maximumDegree: return -1

  var redMask = initialMask
  var toggleCount = 0'i64
  while true:
    var badVertex = n
    for vertex in 0 ..< n:
      let bit = 1'u64 shl vertex
      if (redMask and bit) != 0'u64:
        if lovaszTogglePopcount(adjacency[vertex] and redMask) > int(redLimitValue):
          badVertex = vertex
          break
      else:
        let blueMask = vertexMask and (not redMask)
        if lovaszTogglePopcount(adjacency[vertex] and blueMask) > int(blueLimitValue):
          badVertex = vertex
          break
    if badVertex == n: break
    redMask = redMask xor (1'u64 shl badVertex)
    inc toggleCount
  (toggleCount shl n) or int64(redMask)
