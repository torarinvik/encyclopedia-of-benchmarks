const
  MaxOperations = 63
  MaxBuckets = 32

proc bucketIndex(key: int64; level, split: int): int =
  let base = 1 shl level
  var remainder = key mod int64(base)
  if remainder < 0: remainder += int64(base)
  result = int(remainder)
  if result < split:
    remainder = key mod int64(base shl 1)
    if remainder < 0: remainder += int64(base shl 1)
    result = int(remainder)

proc linear_hashing_trace*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "linear_hashing_trace".} =
  if values == nil or length < 1 or length > 128: return -1
  let operationCount = values[0]
  if operationCount < 0 or operationCount > MaxOperations: return -1
  if length != csize_t(1 + 2 * operationCount): return -1

  var heads: array[MaxBuckets, int32]
  var keys: array[MaxOperations, int64]
  var links: array[MaxOperations, int32]
  for head in heads.mitems: head = -1
  var level = 1
  var split = 0
  var liveCount = 0
  var allocated = 0
  var answer: int64 = 0

  for operation in 0 ..< int(operationCount):
    let opcode = values[1 + 2 * operation]
    let key = values[2 + 2 * operation]
    if opcode < 0 or opcode > 2 or key < -1024 or key > 1023: return -1
    let bucket = bucketIndex(key, level, split)
    var previous: int32 = -1
    var node = heads[bucket]
    while node != -1 and keys[int(node)] != key:
      previous = node
      node = links[int(node)]
    let found = node != -1
    var succeeded: int64 = 0

    if opcode == 0 and not found:
      node = int32(allocated)
      inc allocated
      keys[int(node)] = key
      links[int(node)] = heads[bucket]
      heads[bucket] = node
      inc liveCount
      succeeded = 1
      let base = 1 shl level
      let bucketCount = base + split
      if bucketCount < MaxBuckets and liveCount > 2 * bucketCount:
        let oldBucket = split
        let newBucket = base + split
        var current = heads[oldBucket]
        heads[oldBucket] = -1
        while current != -1:
          let following = links[int(current)]
          var remainder = keys[int(current)] mod int64(base shl 1)
          if remainder < 0: remainder += int64(base shl 1)
          if int(remainder) == newBucket:
            links[int(current)] = heads[newBucket]
            heads[newBucket] = current
          else:
            links[int(current)] = heads[oldBucket]
            heads[oldBucket] = current
          current = following
        inc split
        if split == base:
          inc level
          split = 0
    elif opcode == 1 and found:
      if previous == -1: heads[bucket] = links[int(node)]
      else: links[int(previous)] = links[int(node)]
      dec liveCount
      succeeded = 1
    elif opcode == 2 and found:
      succeeded = 1
    answer = (answer shl 1) or succeeded
  answer
