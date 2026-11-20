const MaxKeys = 256
const MaxQueries = 256
const UniverseBits = 16
const BucketSize = 16
const MaxBuckets = MaxKeys div BucketSize
const MaxTrieNodes = 1 + MaxBuckets * UniverseBits
const MaxParseableInputLength = 515

type TrieNode = object
  child: array[2, int]
  minRank: int
  leafRank: int

proc y_fast_trie_static_predecessor*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "y_fast_trie_static_predecessor".} =
  if input.isNil or length < csize_t(2) or length > csize_t(MaxParseableInputLength): return -1
  let keyCountValue = input[0]
  let queryCountValue = input[1]
  if keyCountValue < 0'i64 or keyCountValue > int64(MaxKeys) or
      queryCountValue < 0'i64 or queryCountValue > int64(MaxQueries): return -1
  let keyCount = int(keyCountValue)
  let queryCount = int(queryCountValue)
  if length != csize_t(2 + keyCount + queryCount): return -1

  var keys: array[MaxKeys, int64]
  for index in 0..<keyCount:
    keys[index] = input[2 + index]
    if keys[index] < 0'i64 or keys[index] > 65535'i64: return -1
  for index in 1..<keyCount:
    let key = keys[index]
    var position = index
    while position > 0 and key < keys[position - 1]:
      keys[position] = keys[position - 1]
      dec position
    keys[position] = key
  for index in 1..<keyCount:
    if keys[index] == keys[index - 1]: return -1
  for index in 0..<queryCount:
    let query = input[2 + keyCount + index]
    if query < 0'i64 or query > 65535'i64: return -1
  if keyCount == 0 or queryCount == 0: return 0

  let bucketCount = (keyCount + BucketSize - 1) div BucketSize
  var nodes: array[MaxTrieNodes, TrieNode]
  for nodeIndex in 0..<MaxTrieNodes:
    nodes[nodeIndex].child = [-1, -1]
    nodes[nodeIndex].minRank = -1
    nodes[nodeIndex].leafRank = -1
  var nodeCount = 1
  for bucket in 0..<bucketCount:
    let bucketStart = bucket * BucketSize
    let bucketEnd = min(bucketStart + BucketSize, keyCount)
    let separator = keys[bucketEnd - 1]
    var node = 0
    if nodes[node].minRank < 0: nodes[node].minRank = bucket
    for bit in countdown(UniverseBits - 1, 0):
      let direction = int((separator shr bit) and 1'i64)
      var next = nodes[node].child[direction]
      if next < 0:
        next = nodeCount
        inc nodeCount
        nodes[node].child[direction] = next
        nodes[next].child = [-1, -1]
        nodes[next].minRank = -1
        nodes[next].leafRank = -1
      node = next
      if nodes[node].minRank < 0: nodes[node].minRank = bucket
    nodes[node].leafRank = bucket

  var checksum = 0'i64
  for queryIndex in 0..<queryCount:
    let query = input[2 + keyCount + queryIndex]
    var node = 0
    var bestSuccessor = -1
    var pathAlive = true
    for bit in countdown(UniverseBits - 1, 0):
      let direction = int((query shr bit) and 1'i64)
      if direction == 0:
        let right = nodes[node].child[1]
        if right >= 0: bestSuccessor = nodes[right].minRank
      let next = nodes[node].child[direction]
      if next < 0:
        pathAlive = false
        break
      node = next
    var bucket = bucketCount - 1
    if pathAlive and nodes[node].leafRank >= 0:
      bucket = nodes[node].leafRank
    elif bestSuccessor >= 0:
      bucket = bestSuccessor

    let bucketStart = bucket * BucketSize
    let bucketEnd = min(bucketStart + BucketSize, keyCount)
    var low = bucketStart
    var high = bucketEnd
    while low < high:
      let middle = low + (high - low) div 2
      if keys[middle] < query: low = middle + 1 else: high = middle
    let lowerBound = low

    var predecessor = -1'i64
    if lowerBound > bucketStart:
      predecessor = keys[lowerBound - 1]
    elif bucket > 0:
      predecessor = keys[bucketStart - 1]

    var successorIndex = lowerBound
    if successorIndex < bucketEnd and keys[successorIndex] == query: inc successorIndex
    var successor = -1'i64
    if successorIndex < bucketEnd:
      successor = keys[successorIndex]
    elif bucket + 1 < bucketCount:
      successor = keys[bucketEnd]

    checksum += int64(queryIndex + 1) *
      ((predecessor + 1'i64) + 65537'i64 * (successor + 1'i64))
  checksum
