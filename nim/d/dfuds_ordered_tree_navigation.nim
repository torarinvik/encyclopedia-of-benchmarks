const
  MaxN = 31
  MaxQ = 32
  MaxInput = 129
  MaxBits = 2 * MaxN
  MaxOutputWords = 4 + MaxQ

proc bitAt(bits: uint64, position: int): bool =
  ((bits shr (position - 1)) and 1'u64) != 0

proc findClose(bits: uint64, bitLength, start: int): int =
  var balance = 0
  for position in start .. bitLength:
    if bitAt(bits, position): inc balance else: dec balance
    if balance == 0: return position
  bitLength + 1

proc findOpen(bits: uint64, position: int): int =
  if bitAt(bits, position): return position
  var balance = 0
  var candidate = position
  while candidate > 0:
    if bitAt(bits, candidate): dec balance else: inc balance
    if balance == 0: return candidate
    dec candidate
  0

proc previousZero(bits: uint64, position: int): int =
  var candidate = position
  while candidate > 1:
    if not bitAt(bits, candidate - 1): return candidate - 1
    dec candidate
  0

proc storeI64Le(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8((bits shr (8 * byte)) and 255'u64)

proc dfuds_ordered_tree_navigation*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "dfuds_ordered_tree_navigation".} =
  if input == nil or length < csize_t(2) or length > csize_t(MaxInput): return -1
  let nValue = input[0]
  let qValue = input[1]
  if nValue < 1 or nValue > int64(MaxN) or qValue < 0 or qValue > int64(MaxQ): return -1
  let n = int(nValue)
  let q = int(qValue)
  if int(length) != 2 + n - 1 + 3 * q: return -1

  var parent: array[MaxN, int]
  for vertex in 1 ..< n:
    let value = input[1 + vertex]
    if value < 0 or value >= int64(vertex): return -1
    parent[vertex] = int(value)
  let queryBase = n + 1
  for index in 0 ..< q:
    let offset = queryBase + 3 * index
    let opcode = input[offset]
    let node = input[offset + 1]
    let argument = input[offset + 2]
    if node < 0 or node >= nValue: return -1
    if opcode == 0 or opcode == 2:
      if argument != 0: return -1
    elif opcode == 1:
      if argument < 0 or argument > nValue: return -1
    else:
      return -1

  var order, stackNode, nextChild: array[MaxN, int]
  var orderCount = 1
  var depth = 1
  while depth > 0:
    let frame = depth - 1
    let node = stackNode[frame]
    var child = nextChild[frame]
    while child < n and parent[child] != node: inc child
    if child < n:
      nextChild[frame] = child + 1
      order[orderCount] = child
      inc orderCount
      stackNode[depth] = child
      nextChild[depth] = 1
      inc depth
    else:
      dec depth
  if orderCount != n: return -1

  var descriptor: array[MaxN, int]
  var positionToNode: array[MaxBits + 2, int]
  for position in 0 ..< MaxBits + 2: positionToNode[position] = -1
  var packed = 1'u64
  var bitLength = 1
  for node in 0 ..< n:
    var degree = 0
    for child in 1 ..< n:
      if parent[child] == order[node]: inc degree
    descriptor[node] = bitLength + 1
    positionToNode[descriptor[node]] = node
    for _ in 0 ..< degree:
      packed = packed or (1'u64 shl bitLength)
      inc bitLength
    inc bitLength
  if bitLength != 2 * n: return -1

  var words: array[MaxOutputWords, int64]
  words[0] = nValue
  words[1] = int64(bitLength)
  words[2] = cast[int64](packed)
  words[3] = qValue
  for index in 0 ..< q:
    let offset = queryBase + 3 * index
    let opcode = input[offset]
    let node = int(input[offset + 1])
    let argument = input[offset + 2]
    let start = descriptor[node]
    var degree = 0
    while start + degree <= bitLength and bitAt(packed, start + degree): inc degree
    var answer = -1'i64
    if opcode == 0:
      answer = int64(degree)
    elif opcode == 1:
      if argument < int64(degree):
        let target = start + degree - (int(argument) + 1)
        let childStart = findClose(packed, bitLength, target) + 1
        if childStart > MaxBits + 1 or positionToNode[childStart] < 0: return -1
        answer = int64(positionToNode[childStart])
    elif node != 0:
      let matchedOpen = findOpen(packed, start - 1)
      let parentPosition = previousZero(packed, matchedOpen) + 1
      if parentPosition == 1:
        answer = 0
      elif parentPosition <= MaxBits + 1 and positionToNode[parentPosition] >= 0:
        answer = int64(positionToNode[parentPosition])
      else:
        return -1
    words[4 + index] = answer

  let required = 8 * (4 + q)
  if output == nil or capacity < csize_t(required): return -2
  for index in 0 ..< 4 + q: storeI64Le(output, 8 * index, words[index])
  int64(required)
