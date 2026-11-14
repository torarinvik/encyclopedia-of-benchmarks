const B = 4
const MaxInitial = 16
const MaxOps = 64
const MaxInserts = 32
const MaxAccesses = 32
const MaxNodes = 16
const MaxItems = 48
const MaxParseable = 179

proc indexed_block_list*(input: ptr UncheckedArray[int64], length: csize_t,
                         output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "indexed_block_list".} =
  if input == nil or length < 2 or length > MaxParseable: return -1
  if input[0] < 0 or input[0] > MaxInitial: return -1
  let initial = int(input[0])
  if int(length) < initial + 2: return -1
  for i in 0 ..< initial:
    if input[1 + i] < -1_000_000 or input[1 + i] > 1_000_000: return -1
  let rawOps = input[1 + initial]
  if rawOps < 0 or rawOps > MaxOps: return -1
  var cursor = initial + 2
  var size = initial
  var inserts = 0
  var accesses = 0
  for op in 0 ..< int(rawOps):
    if cursor >= int(length): return -1
    if input[cursor] == 0:
      if cursor + 3 > int(length): return -1
      let index = input[cursor + 1]
      let value = input[cursor + 2]
      if index < 0 or index > int64(size) or value < -1_000_000 or value > 1_000_000: return -1
      inc inserts
      if inserts > MaxInserts: return -1
      inc size
      cursor += 3
    elif input[cursor] == 1:
      if cursor + 2 > int(length): return -1
      let index = input[cursor + 1]
      if index < 0 or index >= int64(size): return -1
      inc accesses
      if accesses > MaxAccesses: return -1
      cursor += 2
    else: return -1
  if cursor != int(length) or size > MaxItems: return -1
  let required = accesses * 8
  if required > 0 and (output == nil or int(outputCapacity) < required): return -2

  var blocks: array[MaxNodes, array[2 * B + 1, int64]]
  var sizes: array[MaxNodes, int]
  var next: array[MaxNodes, int]
  for i in 0 ..< MaxNodes: next[i] = -1
  var nodeCount = 1
  proc insertBlock(index: int, value: int64) =
    var node = 0
    var offset = 0
    while next[node] >= 0 and index > offset + sizes[node]:
      offset += sizes[node]
      node = next[node]
    let local = index - offset
    var j = sizes[node]
    while j > local:
      blocks[node][j] = blocks[node][j - 1]
      dec j
    blocks[node][local] = value
    inc sizes[node]
    if sizes[node] > 2 * B:
      let fresh = nodeCount
      inc nodeCount
      let firstMoved = sizes[node] - B
      for k in 0 ..< B: blocks[fresh][k] = blocks[node][firstMoved + k]
      sizes[fresh] = B
      sizes[node] -= B
      next[fresh] = next[node]
      next[node] = fresh
  proc getBlock(index: int): int64 =
    var node = 0
    var offset = 0
    while index >= offset + sizes[node]:
      offset += sizes[node]
      node = next[node]
    blocks[node][index - offset]

  for i in 0 ..< initial: insertBlock(i, input[1 + i])
  let operationCount = int(input[1 + initial])
  cursor = initial + 2
  var answerCount = 0
  var answers: array[MaxAccesses, int64]
  for op in 0 ..< operationCount:
    let opcode = input[cursor]
    let index = int(input[cursor + 1])
    if opcode == 0:
      insertBlock(index, input[cursor + 2])
      cursor += 3
    else:
      answers[answerCount] = getBlock(index)
      inc answerCount
      cursor += 2
  for i in 0 ..< answerCount:
    let bytes = cast[uint64](answers[i])
    for b in 0 ..< 8: output[8 * i + b] = uint8((bytes shr (8 * b)) and 255)
  int64(required)
