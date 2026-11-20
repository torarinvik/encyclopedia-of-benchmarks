const MaxNodes = 32
const MaxQueries = 32
const MaxInputWords = 130
const MaxOutputWords = 4 + MaxQueries

proc storeI64Le(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8((bits shr (8 * byte)) and 255)

proc louds_ordered_tree_navigation*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "louds_ordered_tree_navigation".} =
  if input.isNil or length < 2 or length > csize_t(MaxInputWords): return -1
  let nValue = input[0]
  let qValue = input[1]
  if nValue < 1 or nValue > MaxNodes or qValue < 0 or qValue > MaxQueries: return -1
  let n = int(nValue)
  let q = int(qValue)
  if length != csize_t(2 + (n - 1) + 3 * q): return -1

  var parent: array[MaxNodes, int]
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
    if opcode == 0 or opcode == 1:
      if argument != 0: return -1
    elif opcode == 2:
      if argument < 0 or argument > nValue: return -1
    else: return -1

  var order: array[MaxNodes, int]
  var orderCount = 1
  var cursor = 0
  while cursor < orderCount:
    let vertex = order[cursor]
    for child in 1 ..< n:
      if parent[child] == vertex:
        order[orderCount] = child
        inc orderCount
    inc cursor
  if orderCount != n: return -1

  var degree: array[MaxNodes, int]
  for node in 0 ..< n:
    for child in 1 ..< n:
      if parent[child] == order[node]: inc degree[node]

  var packed: uint64 = 0
  var bitLength = 0
  for node in 0 ..< n:
    for child in 0 ..< degree[node]:
      packed = packed or (1'u64 shl bitLength)
      inc bitLength
    inc bitLength

  var decoded, rankPrefix: array[MaxNodes + 1, int]
  var bitPosition = 0
  var previousZero = -1
  for node in 0 ..< n:
    while bitPosition < bitLength and ((packed shr bitPosition) and 1) != 0: inc bitPosition
    decoded[node] = bitPosition - previousZero - 1
    previousZero = bitPosition
    inc bitPosition
    rankPrefix[node + 1] = rankPrefix[node] + decoded[node]

  var words: array[MaxOutputWords, int64]
  words[0] = nValue
  words[1] = int64(bitLength)
  words[2] = int64(packed)
  words[3] = qValue
  for index in 0 ..< q:
    let offset = queryBase + 3 * index
    let opcode = input[offset]
    let node = int(input[offset + 1])
    let argument = input[offset + 2]
    var answer: int64 = -1
    if opcode == 0:
      answer = int64(decoded[node])
    elif opcode == 1:
      if node != 0:
        for candidate in 0 ..< n:
          if rankPrefix[candidate + 1] >= node:
            answer = int64(candidate)
            break
    elif int(argument) < decoded[node]:
      answer = int64(1 + rankPrefix[node] + int(argument))
    words[4 + index] = answer

  let outputWords = 4 + q
  let required = 8 * outputWords
  if output.isNil or capacity < csize_t(required): return -2
  for index in 0 ..< outputWords:
    storeI64Le(output, 8 * index, words[index])
  int64(required)
