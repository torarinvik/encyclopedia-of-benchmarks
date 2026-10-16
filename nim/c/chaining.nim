type I64Input = ptr UncheckedArray[int64]

proc chaining*(input: I64Input, length: csize_t): int64
    {.cdecl, exportc: "chaining".} =
  if input == nil or length < 2 or length > 260: return -1
  let bucketCountValue = input[0]
  let operationCountValue = input[1]
  if bucketCountValue < 1 or bucketCountValue > 127 or operationCountValue < 0 or operationCountValue > 128:
    return -1
  let bucketCount = int(bucketCountValue)
  let operationCount = int(operationCountValue)
  if int(length) != 2 + 2 * operationCount: return -1

  var heads: array[127, int64]
  var keys: array[128, int64]
  var next: array[128, int64]
  for bucket in 0 ..< bucketCount:
    heads[bucket] = -1
  var inserted = 0
  var queryCount = 0
  var result = 0'i64
  for operationIndex in 0 ..< operationCount:
    let operation = input[2 + 2 * operationIndex]
    let key = input[3 + 2 * operationIndex]
    if (operation != 0 and operation != 1) or key < 0 or key > int64(high(int32)):
      return -1
    let bucket = int(key mod bucketCountValue)
    if operation == 0:
      if inserted >= keys.len: return -1
      keys[inserted] = key
      next[inserted] = -1
      if heads[bucket] < 0: heads[bucket] = int64(inserted)
      else:
        var node = heads[bucket]
        while next[int(node)] >= 0: node = next[int(node)]
        next[int(node)] = int64(inserted)
      inc inserted
    else:
      if queryCount >= 63: return -1
      var node = heads[bucket]
      while node >= 0 and keys[int(node)] != key: node = next[int(node)]
      if node >= 0: result = result or (1'i64 shl queryCount)
      inc queryCount
  result
