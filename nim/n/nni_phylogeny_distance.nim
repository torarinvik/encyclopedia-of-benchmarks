const
  MaxLeaves = 7
  MaxEdges = 11
  MaxInput = 23
  MaxStates = 945
  MaxDegree = 8

proc storeI64Le(output: ptr UncheckedArray[uint8], value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8: output[byte] = uint8((bits shr (8 * byte)) and 255)

proc bitCount(value: uint16, n: int): int =
  for bit in 0 ..< n: result += int((value shr bit) and 1)

proc validTree(input: ptr UncheckedArray[int64], offset, n, edges: int): bool =
  var splits: array[MaxEdges, uint16]
  var internal: array[MaxEdges, uint16]
  var internalCount = 0
  let universe = uint16((1 shl n) - 1)
  for i in 0 ..< edges:
    let raw = input[offset + i]
    if raw <= 0 or uint64(raw) >= uint64(universe) or (raw and 1) != 0: return false
    splits[i] = uint16(raw)
    for earlier in 0 ..< i:
      if splits[earlier] == splits[i]: return false
    let count = bitCount(splits[i], n)
    if count == 1 or count == n - 1:
      if count == n - 1 and splits[i] != (universe xor 1'u16): return false
    elif count >= 2 and count <= n - 2:
      internal[internalCount] = splits[i]
      inc internalCount
    else:
      return false
  if internalCount != n - 3: return false
  for leaf in 1 ..< n:
    let pendant = uint16(1 shl leaf)
    var found = 0
    for edge in 0 ..< edges:
      if splits[edge] == pendant: inc found
    if found != 1: return false
  var rootPendant = 0
  for edge in 0 ..< edges:
    if splits[edge] == (universe xor 1'u16): inc rootPendant
  if rootPendant != 1: return false
  for i in 0 ..< internalCount:
    for j in i + 1 ..< internalCount:
      let common = internal[i] and internal[j]
      if common != 0 and common != internal[i] and common != internal[j]: return false
  true

proc sortState(state: ptr UncheckedArray[uint16], count: int) =
  for i in 1 ..< count:
    let value = state[i]
    var j = i
    while j > 0 and state[j - 1] > value:
      state[j] = state[j - 1]
      dec j
    state[j] = value

proc sameState(left, right: ptr UncheckedArray[uint16], edges: int): bool =
  for i in 0 ..< edges:
    if left[i] != right[i]: return false
  true

proc enumerateStates(leaves: int, a, b: ptr UncheckedArray[uint16], stateCount: var int): ptr UncheckedArray[uint16] =
  var current = a
  var next = b
  current[0] = 2; current[1] = 4; current[2] = 6
  stateCount = 1
  var oldEdges = 3
  for size in 4 .. leaves:
    let newEdges = oldEdges + 2
    let newBit = uint16(1 shl (size - 1))
    var nextCount = 0
    for stateIndex in 0 ..< stateCount:
      let old = cast[ptr UncheckedArray[uint16]](cast[uint](current) + uint(stateIndex * MaxEdges * sizeof(uint16)))
      for selectedIndex in 0 ..< oldEdges:
        let selected = old[selectedIndex]
        var candidate: array[MaxEdges, uint16]
        var candidateCount = 0
        for edge in 0 ..< oldEdges:
          let split = old[edge]
          if split == selected:
            candidate[candidateCount] = split; inc candidateCount
            candidate[candidateCount] = split or newBit; inc candidateCount
          elif (selected and split) == selected:
            candidate[candidateCount] = split or newBit; inc candidateCount
          else:
            candidate[candidateCount] = split; inc candidateCount
        candidate[candidateCount] = newBit; inc candidateCount
        sortState(addr candidate[0], candidateCount)
        var found = 0
        while found < nextCount:
          let prior = cast[ptr UncheckedArray[uint16]](cast[uint](next) + uint(found * MaxEdges * sizeof(uint16)))
          if sameState(prior, addr candidate[0], newEdges): break
          inc found
        if found == nextCount:
          if nextCount >= MaxStates: return nil
          let destination = cast[ptr UncheckedArray[uint16]](cast[uint](next) + uint(nextCount * MaxEdges * sizeof(uint16)))
          for edge in 0 ..< newEdges: destination[edge] = candidate[edge]
          inc nextCount
    swap(current, next)
    stateCount = nextCount
    oldEdges = newEdges
  current

proc nni_phylogeny_distance*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "nni_phylogeny_distance".} =
  if input.isNil or length < csize_t(7) or length > csize_t(MaxInput): return -1
  let leafValue = input[0]
  if leafValue < 3 or leafValue > MaxLeaves: return -1
  let leaves = int(leafValue)
  let edges = 2 * leaves - 3
  if int(length) != 1 + 2 * edges or not validTree(input, 1, leaves, edges)
      or not validTree(input, 1 + edges, leaves, edges): return -1

  var statesA: array[MaxStates * MaxEdges, uint16]
  var statesB: array[MaxStates * MaxEdges, uint16]
  var stateCount = 0
  let states = enumerateStates(leaves, cast[ptr UncheckedArray[uint16]](addr statesA[0]),
    cast[ptr UncheckedArray[uint16]](addr statesB[0]), stateCount)
  if states.isNil: return -1
  var start: array[MaxEdges, uint16]
  var goal: array[MaxEdges, uint16]
  for i in 0 ..< edges:
    start[i] = uint16(input[1 + i])
    goal[i] = uint16(input[1 + edges + i])
  sortState(addr start[0], edges)
  sortState(addr goal[0], edges)
  var startIndex = stateCount
  var goalIndex = stateCount
  for i in 0 ..< stateCount:
    let state = cast[ptr UncheckedArray[uint16]](cast[uint](states) + uint(i * MaxEdges * sizeof(uint16)))
    if sameState(state, addr start[0], edges): startIndex = i
    if sameState(state, addr goal[0], edges): goalIndex = i
  if startIndex == stateCount or goalIndex == stateCount: return -1

  var neighbors: array[MaxStates * MaxDegree, uint16]
  var degree: array[MaxStates, uint8]
  for left in 0 ..< stateCount:
    let leftState = cast[ptr UncheckedArray[uint16]](cast[uint](states) + uint(left * MaxEdges * sizeof(uint16)))
    for right in left + 1 ..< stateCount:
      let rightState = cast[ptr UncheckedArray[uint16]](cast[uint](states) + uint(right * MaxEdges * sizeof(uint16)))
      var common = 0
      for i in 0 ..< edges:
        let leftSize = bitCount(leftState[i], leaves)
        if leftSize < 2 or leftSize > leaves - 2: continue
        for j in 0 ..< edges:
          let rightSize = bitCount(rightState[j], leaves)
          if rightSize >= 2 and rightSize <= leaves - 2 and leftState[i] == rightState[j]: inc common; break
      if common + leaves == edges - 1:
        if degree[left] >= MaxDegree or degree[right] >= MaxDegree: return -1
        neighbors[left * MaxDegree + int(degree[left])] = uint16(right)
        inc degree[left]
        neighbors[right * MaxDegree + int(degree[right])] = uint16(left)
        inc degree[right]
  var distance: array[MaxStates, int16]
  var queue: array[MaxStates, uint16]
  for i in 0 ..< stateCount: distance[i] = -1
  var head = 0
  var tail = 0
  distance[startIndex] = 0
  queue[tail] = uint16(startIndex); inc tail
  while head < tail:
    let current = int(queue[head]); inc head
    if current == goalIndex: break
    for i in 0 ..< int(degree[current]):
      let next = int(neighbors[current * MaxDegree + i])
      if distance[next] < 0:
        distance[next] = distance[current] + 1
        queue[tail] = uint16(next); inc tail
  if distance[goalIndex] < 0: return -1
  if output.isNil or capacity < csize_t(8): return -2
  var staged: array[8, uint8]
  storeI64Le(cast[ptr UncheckedArray[uint8]](addr staged[0]), int64(distance[goalIndex]))
  for byte in 0 ..< 8: output[byte] = staged[byte]
  8
