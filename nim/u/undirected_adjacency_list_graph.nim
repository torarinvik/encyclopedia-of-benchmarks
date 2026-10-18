const MaxNodes = 8
const MaxOperations = 24
const MaxParseableInputLength = 98
const MaxOutputWords = 144

proc pushWord(words: var array[MaxOutputWords, int64], count: var int, value: int64) =
  words[count] = value
  inc count

proc pushRecord(words: var array[MaxOutputWords, int64], count: var int,
                opcode: int64, payload: openArray[int64]) =
  pushWord(words, count, opcode)
  pushWord(words, count, int64(payload.len))
  for value in payload:
    pushWord(words, count, value)

proc storeI64Le(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8((bits shr (8 * byte)) and 255'u64)

proc undirected_adjacency_list_graph*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "undirected_adjacency_list_graph".} =
  if input.isNil or length < csize_t(1) or length > csize_t(MaxParseableInputLength): return -1
  if input[0] < 0 or input[0] > MaxOperations: return -1
  let operationCount = int(input[0])
  if int(length) != 1 + 4 * operationCount: return -1

  var words: array[MaxOutputWords, int64]
  var wordCount = 0
  var edgeWeights: array[MaxNodes, array[MaxNodes, int64]]
  var hasEdge: array[MaxNodes, array[MaxNodes, bool]]
  var nodeCount = 0

  for operationIndex in 0 ..< operationCount:
    let base = 1 + 4 * operationIndex
    let opcode = input[base]
    let first = input[base + 1]
    let second = input[base + 2]
    let third = input[base + 3]
    if opcode < 0 or opcode > 4: return -1

    if opcode == 0 or opcode == 4:
      if first != 0 or second != 0 or third != 0: return -1
    elif opcode == 1:
      if first < int64(low(int32)) or first > int64(high(int32)) or
          second < int64(low(int32)) or second > int64(high(int32)) or
          third < int64(low(int32)) or third > int64(high(int32)): return -1
    elif opcode == 2:
      if first < int64(low(int32)) or first > int64(high(int32)) or second != 0 or third != 0: return -1
    else:
      if first < int64(low(int32)) or first > int64(high(int32)) or
          second < int64(low(int32)) or second > int64(high(int32)) or third != 0: return -1

    if opcode == 0:
      if nodeCount >= MaxNodes: return -1
      pushRecord(words, wordCount, opcode, [int64(nodeCount)])
      inc nodeCount
    elif opcode == 1:
      var added = false
      if first >= 0 and first < int64(nodeCount) and second >= 0 and second < int64(nodeCount):
        let origin = int(first)
        let destination = int(second)
        if not hasEdge[origin][destination]:
          hasEdge[origin][destination] = true
          hasEdge[destination][origin] = true
          edgeWeights[origin][destination] = third
          edgeWeights[destination][origin] = third
          added = true
      pushRecord(words, wordCount, opcode, [if added: 1'i64 else: 0'i64])
    elif opcode == 2:
      if first < 0 or first >= int64(nodeCount): return -1
      let origin = int(first)
      var payload: array[MaxNodes + 1, int64]
      var neighborCount = 0
      for neighbor in 0 ..< nodeCount:
        if hasEdge[origin][neighbor]:
          payload[neighborCount + 1] = int64(neighbor)
          inc neighborCount
      payload[0] = int64(neighborCount)
      pushRecord(words, wordCount, opcode, payload.toOpenArray(0, neighborCount))
    elif opcode == 3:
      if first < 0 or first >= int64(nodeCount): return -1
      let origin = int(first)
      var present = false
      var weight = 0'i64
      if second >= 0 and second < int64(nodeCount) and hasEdge[origin][int(second)]:
        present = true
        weight = edgeWeights[origin][int(second)]
      pushRecord(words, wordCount, opcode, [if present: 1'i64 else: 0'i64, weight])
    else:
      pushRecord(words, wordCount, opcode, [int64(nodeCount)])

  let outputBytes = wordCount * 8
  if output.isNil or outputCapacity < csize_t(outputBytes): return -2
  for index in 0 ..< wordCount:
    storeI64Le(output, index * 8, words[index])
  int64(outputBytes)
