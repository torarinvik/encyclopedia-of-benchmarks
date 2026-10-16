const
  MaxVertices = 8
  MaxEdges = 28
  MaxOperations = 128
  MaxInputLength = 599
  MinWeight = -1_000_000'i64
  MaxWeight = 1_000_000'i64
  FnvOffset = 0xcbf29ce484222325'u64
  FnvPrime = 0x100000001b3'u64
  ResultMask = 0x7fffffffffffffff'u64

proc hashByte(hash: uint64, value: uint8): uint64 =
  (hash xor uint64(value)) *% FnvPrime

proc hashI32(hashValue: uint64, value: int64): uint64 =
  var hash = hashValue
  let bits = cast[uint32](int32(value))
  for shift in countup(0, 24, 8):
    hash = hashByte(hash, uint8((bits shr shift) and 255))
  hash

proc hashU32(hashValue: uint64, value: uint32): uint64 =
  var hash = hashValue
  for shift in countup(0, 24, 8):
    hash = hashByte(hash, uint8((value shr shift) and 255))
  hash

proc edgeBitIndex(n, uInput, vInput: int): int =
  var u = uInput
  var v = vInput
  if u > v: swap(u, v)
  for first in 0 ..< u: result += n - first - 1
  result += v - u - 1

proc componentCount(n: int, present: openArray[uint8]): int =
  var seen: array[MaxVertices, bool]
  for root in 0 ..< n:
    if seen[root]: continue
    inc result
    var stack: array[MaxVertices, int]
    var size = 1
    seen[root] = true
    stack[0] = root
    while size > 0:
      dec size
      let node = stack[size]
      for neighbor in 0 ..< n:
        if present[node * MaxVertices + neighbor] != 0 and not seen[neighbor]:
          seen[neighbor] = true
          stack[size] = neighbor
          inc size

proc primForest(n: int, present: openArray[uint8], weights: openArray[int64]): (int, uint32) =
  var inForest: array[MaxVertices, bool]
  var bestWeight: array[MaxVertices, int64]
  var bestParent: array[MaxVertices, int]
  for i in 0 ..< MaxVertices: bestParent[i] = -1
  var components = 0
  var edgeMask = 0'u32
  for root in 0 ..< n:
    if inForest[root]: continue
    inc components
    inForest[root] = true
    for neighbor in 0 ..< n:
      let index = root * MaxVertices + neighbor
      if present[index] != 0 and not inForest[neighbor]:
        bestWeight[neighbor] = weights[index]
        bestParent[neighbor] = root
    while true:
      var selected = -1
      for candidate in 0 ..< n:
        if inForest[candidate] or bestParent[candidate] < 0: continue
        if selected < 0 or bestWeight[candidate] < bestWeight[selected]: selected = candidate
      if selected < 0: break
      let parent = bestParent[selected]
      edgeMask = edgeMask or (1'u32 shl edgeBitIndex(n, parent, selected))
      inForest[selected] = true
      bestParent[selected] = -1
      for neighbor in 0 ..< n:
        let index = selected * MaxVertices + neighbor
        if present[index] != 0 and not inForest[neighbor] and
            (bestParent[neighbor] < 0 or weights[index] < bestWeight[neighbor]):
          bestWeight[neighbor] = weights[index]
          bestParent[neighbor] = selected
  (components, edgeMask)

proc findRoot(parent: var array[MaxVertices, int], nodeInput: int): int =
  result = nodeInput
  while parent[result] != result:
    parent[result] = parent[parent[result]]
    result = parent[result]

proc kruskalForest(n: int, present: openArray[uint8], weights: openArray[int64]): (int, uint32) =
  var edgeU, edgeV: array[MaxEdges, int]
  var edgeWeight: array[MaxEdges, int64]
  var edgeCount = 0
  for u in 0 ..< n:
    for v in u + 1 ..< n:
      let index = u * MaxVertices + v
      if present[index] != 0:
        edgeU[edgeCount] = u
        edgeV[edgeCount] = v
        edgeWeight[edgeCount] = weights[index]
        inc edgeCount
  for i in 1 ..< edgeCount:
    let u = edgeU[i]
    let v = edgeV[i]
    let weight = edgeWeight[i]
    var j = i
    while j > 0 and edgeWeight[j - 1] > weight:
      edgeU[j] = edgeU[j - 1]
      edgeV[j] = edgeV[j - 1]
      edgeWeight[j] = edgeWeight[j - 1]
      dec j
    edgeU[j] = u
    edgeV[j] = v
    edgeWeight[j] = weight

  var parent: array[MaxVertices, int]
  var rank: array[MaxVertices, int]
  for i in 0 ..< n: parent[i] = i
  var components = n
  var edgeMask = 0'u32
  for i in 0 ..< edgeCount:
    let left = findRoot(parent, edgeU[i])
    let right = findRoot(parent, edgeV[i])
    if left == right: continue
    if rank[left] < rank[right]: parent[left] = right
    elif rank[left] > rank[right]: parent[right] = left
    else:
      parent[right] = left
      inc rank[left]
    dec components
    edgeMask = edgeMask or (1'u32 shl edgeBitIndex(n, edgeU[i], edgeV[i]))
  (components, edgeMask)

proc undirected_graph*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "undirected_graph".} =
  if input == nil or length < 3 or length > csize_t(MaxInputLength): return -1
  let nValue = input[0]
  let initialCountValue = input[1]
  if nValue < 0 or nValue > MaxVertices or initialCountValue < 0 or initialCountValue > MaxEdges:
    return -1
  let n = int(nValue)
  let initialCount = int(initialCountValue)
  if initialCount > n * (n - 1) div 2: return -1
  let countPosition = 2 + 3 * initialCount
  if csize_t(countPosition) >= length: return -1
  let operationCountValue = input[countPosition]
  if operationCountValue < 0 or operationCountValue > MaxOperations or
      length != csize_t(3 + 3 * initialCount + 4 * operationCountValue): return -1

  var present: array[MaxVertices * MaxVertices, uint8]
  var weights: array[MaxVertices * MaxVertices, int64]
  for edge in 0 ..< initialCount:
    let position = 2 + 3 * edge
    let uValue = input[position]
    let vValue = input[position + 1]
    let weight = input[position + 2]
    if uValue < 0 or uValue >= vValue or vValue >= nValue or weight < MinWeight or weight > MaxWeight:
      return -1
    let u = int(uValue)
    let v = int(vValue)
    if present[u * MaxVertices + v] != 0: return -1
    for first in 0 ..< n:
      for second in first + 1 ..< n:
        let index = first * MaxVertices + second
        if present[index] != 0 and weights[index] == weight: return -1
    present[u * MaxVertices + v] = 1
    present[v * MaxVertices + u] = 1
    weights[u * MaxVertices + v] = weight
    weights[v * MaxVertices + u] = weight

  var hash = FnvOffset
  for operation in 0 ..< int(operationCountValue):
    let position = countPosition + 1 + 4 * operation
    let opcode = input[position]
    let uValue = input[position + 1]
    let vValue = input[position + 2]
    let weight = input[position + 3]
    var resultCode = 0'u8
    if opcode == 0:
      if uValue < 0 or uValue >= nValue or vValue < 0 or vValue >= nValue or uValue == vValue or
          weight < MinWeight or weight > MaxWeight: return -1
      let u = int(uValue)
      let v = int(vValue)
      let index = u * MaxVertices + v
      let reverse = v * MaxVertices + u
      let oldIndex = if u < v: index else: reverse
      for first in 0 ..< n:
        for second in first + 1 ..< n:
          let other = first * MaxVertices + second
          if other != oldIndex and present[other] != 0 and weights[other] == weight: return -1
      present[index] = 1
      present[reverse] = 1
      weights[index] = weight
      weights[reverse] = weight
    elif opcode == 1 or opcode == 2:
      if uValue < 0 or uValue >= nValue or vValue < 0 or vValue >= nValue or uValue == vValue or weight != 0:
        return -1
      let u = int(uValue)
      let v = int(vValue)
      let index = u * MaxVertices + v
      let reverse = v * MaxVertices + u
      if opcode == 1:
        present[index] = 0
        present[reverse] = 0
        weights[index] = 0
        weights[reverse] = 0
      else: resultCode = present[index]
    elif opcode == 3:
      if uValue != 0 or vValue != 0 or weight != 0: return -1
      hash = hashByte(hash, uint8(opcode))
      hash = hashByte(hash, resultCode)
      hash = hashByte(hash, uint8(componentCount(n, present)))
      continue
    elif opcode == 4 or opcode == 5 or opcode == 6:
      if uValue != 0 or vValue != 0 or weight != 0: return -1
      let summary = if opcode == 5: kruskalForest(n, present, weights) else: primForest(n, present, weights)
      hash = hashByte(hash, uint8(opcode))
      hash = hashByte(hash, resultCode)
      hash = hashByte(hash, uint8(summary[0]))
      hash = hashU32(hash, summary[1])
      continue
    else:
      return -1
    hash = hashByte(hash, uint8(opcode))
    hash = hashByte(hash, resultCode)

  var activeCount = 0
  for u in 0 ..< n:
    for v in u + 1 ..< n:
      if present[u * MaxVertices + v] != 0: inc activeCount
  hash = hashByte(hash, uint8(n))
  hash = hashByte(hash, uint8(activeCount))
  for u in 0 ..< n:
    for v in u + 1 ..< n:
      let index = u * MaxVertices + v
      if present[index] == 0: continue
      hash = hashByte(hash, uint8(u))
      hash = hashByte(hash, uint8(v))
      hash = hashI32(hash, weights[index])
  cast[int64](hash and ResultMask)
