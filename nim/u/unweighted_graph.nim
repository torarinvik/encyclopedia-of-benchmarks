const
  MaxInitialNodes = 12
  MaxOperations = 16
  MaxKnownIds = MaxInitialNodes + 2 * MaxOperations
  MaxParseableInputLength = 64
  MaxOutputWords = 81
  MaxOutputBytes = 648

proc findId(ids: array[MaxKnownIds, int64], count: int, id: int64): int =
  for index in 0 ..< count:
    if ids[index] == id: return index
  -1

proc ensureId(ids: var array[MaxKnownIds, int64], declared: var array[MaxKnownIds, bool],
              count: var int, id: int64): int =
  let found = findId(ids, count, id)
  if found >= 0: return found
  if count >= MaxKnownIds: return -1
  result = count
  ids[count] = id
  declared[count] = false
  inc count

proc writeI64Le(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8((bits shr (byte * 8)) and 0xff'u64)

proc unweightedGraph*(input: ptr UncheckedArray[int64], inputLength: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "unweighted_graph".} =
  if input == nil or inputLength < 3 or inputLength > MaxParseableInputLength.csize_t: return -1
  if (input[0] != 0 and input[0] != 1) or input[1] < 0 or input[1] > MaxInitialNodes.int64 or
      input[2] < 0 or input[2] > MaxOperations.int64: return -1
  let directed = input[0] == 1
  let initialCount = int(input[1])
  let operationCount = int(input[2])
  if inputLength != csize_t(3 + initialCount + operationCount * 3): return -1

  var ids: array[MaxKnownIds, int64]
  var declared: array[MaxKnownIds, bool]
  var adjacency: array[MaxKnownIds, array[MaxKnownIds, bool]]
  var knownCount = 0
  for index in 0 ..< initialCount:
    let node = input[3 + index]
    if node < int64(low(int32)) or node > int64(high(int32)) or findId(ids, knownCount, node) >= 0: return -1
    let slot = ensureId(ids, declared, knownCount, node)
    if slot < 0: return -1
    declared[slot] = true

  var resultWords: array[MaxOutputWords, int64]
  var resultCount = 0
  let operationsOffset = 3 + initialCount
  for index in 0 ..< operationCount:
    let offset = operationsOffset + index * 3
    let op = input[offset]
    let first = input[offset + 1]
    let second = input[offset + 2]
    if first < int64(low(int32)) or first > int64(high(int32)) or
        second < int64(low(int32)) or second > int64(high(int32)): return -1
    if op == 0:
      if second != 0: return -1
      let existing = findId(ids, knownCount, first)
      if existing >= 0 and declared[existing]: return -1
      let slot = ensureId(ids, declared, knownCount, first)
      if slot < 0: return -1
      declared[slot] = true
    elif op == 1:
      let from = findId(ids, knownCount, first)
      if from < 0 or not declared[from]: return -1
      var to = findId(ids, knownCount, second)
      if not directed and (to < 0 or not declared[to]): return -1
      if to < 0: to = ensureId(ids, declared, knownCount, second)
      if to < 0 or adjacency[from][to]: return -1
      adjacency[from][to] = true
      if not directed: adjacency[to][from] = true
    elif op == 2:
      if second != 0: return -1
      let node = findId(ids, knownCount, first)
      if node < 0 or not declared[node]: return -1
      var sorted: array[MaxKnownIds, int64]
      var neighborCount = 0
      for neighbor in 0 ..< knownCount:
        if adjacency[node][neighbor]:
          sorted[neighborCount] = ids[neighbor]
          inc neighborCount
      for left in 1 ..< neighborCount:
        let value = sorted[left]
        var right = left
        while right > 0 and sorted[right - 1] > value:
          sorted[right] = sorted[right - 1]
          dec right
        sorted[right] = value
      if resultCount + 2 + neighborCount > MaxOutputWords: return -1
      resultWords[resultCount] = first
      resultWords[resultCount + 1] = int64(neighborCount)
      resultCount += 2
      for neighbor in 0 ..< neighborCount:
        resultWords[resultCount] = sorted[neighbor]
        inc resultCount
    else:
      return -1

  let outputBytes = resultCount * 8
  if outputBytes > MaxOutputBytes: return -1
  if output == nil or capacity < csize_t(outputBytes): return -2
  for index in 0 ..< resultCount: writeI64Le(output, index * 8, resultWords[index])
  int64(outputBytes)
