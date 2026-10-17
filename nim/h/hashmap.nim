const
  MaxOperations = 128
  MaxEntries = 128
  MaxInitialCapacity = 64
  MaxCapacity = 256
  MaxInputLength = 2 + 3 * MaxOperations
  FnvOffset = 14695981039346656037'u64
  FnvPrime = 1099511628211'u64

proc hashByte(hashValue: uint64, byte: uint8): uint64 =
  (hashValue xor uint64(byte)) * FnvPrime

proc hashKey(key: int64): uint64 =
  var hashValue = FnvOffset
  var magnitude = uint64(if key < 0: -key else: key)
  var digits: array[10, uint8]
  var count = 0
  while true:
    digits[count] = uint8(magnitude mod 10)
    inc count
    magnitude = magnitude div 10
    if magnitude == 0: break
  if key < 0: hashValue = hashByte(hashValue, uint8(ord('-')))
  while count > 0:
    dec count
    hashValue = hashByte(hashValue, uint8(ord('0') + int(digits[count])))
  hashValue xor (hashValue shr 16)

proc bucketFor(key: int64, capacity: int): int =
  int(hashKey(key) and uint64(capacity - 1))

proc putI64Le(output: ptr UncheckedArray[uint8], word: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[word * 8 + byte] = uint8((bits shr (byte * 8)) and 255'u64)

proc hashmap*(input: ptr UncheckedArray[int64], length: csize_t,
              output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64 {.cdecl, exportc: "hashmap".} =
  if input.isNil or length < 2 or length > csize_t(MaxInputLength): return -1
  let initialCapacity = input[0]
  let operationCount = input[1]
  if initialCapacity < 1 or initialCapacity > MaxInitialCapacity or
      (initialCapacity and (initialCapacity - 1)) != 0 or operationCount < 0 or
      operationCount > MaxOperations or length != csize_t(2 + 3 * operationCount): return -1
  for operation in 0 ..< int(operationCount):
    let op = input[2 + 3 * operation]
    let key = input[3 + 3 * operation]
    let value = input[4 + 3 * operation]
    if op < 0 or op > 2 or key < -2147483648'i64 or key > 2147483647'i64: return -1
    if op == 0:
      if value < -2147483648'i64 or value > 2147483647'i64: return -1
    elif value != 0: return -1

  var keys: array[MaxEntries, int64]
  var values: array[MaxEntries, int64]
  var results: array[1 + 3 * MaxOperations + 2, int64]
  var next: array[MaxEntries, int]
  var heads: array[MaxCapacity, int]
  var tails: array[MaxCapacity, int]
  for i in 0 ..< MaxEntries: next[i] = -1
  for i in 0 ..< MaxCapacity:
    heads[i] = -1
    tails[i] = -1
  var size = 0
  var mapCapacity = int(initialCapacity)
  var resultWords = 1
  var queryCount = 0

  for operation in 0 ..< int(operationCount):
    let op = input[2 + 3 * operation]
    let key = input[3 + 3 * operation]
    let value = input[4 + 3 * operation]
    let bucket = bucketFor(key, mapCapacity)
    var entry = heads[bucket]
    while entry >= 0 and keys[entry] != key: entry = next[entry]
    if op == 0:
      if entry >= 0:
        values[entry] = value
        continue
      if size >= MaxEntries: return -1
      entry = size
      inc size
      keys[entry] = key
      values[entry] = value
      if heads[bucket] < 0: heads[bucket] = entry
      else: next[tails[bucket]] = entry
      tails[bucket] = entry
      if size * 4 > mapCapacity * 3:
        var order: array[MaxEntries, int]
        var orderCount = 0
        for oldBucket in 0 ..< mapCapacity:
          var node = heads[oldBucket]
          while node >= 0:
            order[orderCount] = node
            inc orderCount
            node = next[node]
        mapCapacity *= 2
        for i in 0 ..< MaxCapacity:
          heads[i] = -1
          tails[i] = -1
        for i in 0 ..< size: next[i] = -1
        for i in 0 ..< orderCount:
          let node = order[i]
          let newBucket = bucketFor(keys[node], mapCapacity)
          if heads[newBucket] < 0: heads[newBucket] = node
          else: next[tails[newBucket]] = node
          tails[newBucket] = node
    else:
      results[resultWords] = op
      inc resultWords
      if op == 1:
        results[resultWords] = if entry >= 0: 1'i64 else: 0'i64
        inc resultWords
        results[resultWords] = if entry >= 0: values[entry] else: 0
        inc resultWords
      else:
        results[resultWords] = if entry >= 0: 1'i64 else: 0'i64
        inc resultWords
      inc queryCount

  results[0] = int64(queryCount)
  results[resultWords] = int64(size)
  inc resultWords
  results[resultWords] = int64(mapCapacity)
  inc resultWords
  let outputBytes = resultWords * 8
  if output.isNil or outputCapacity < csize_t(outputBytes): return -2
  for word in 0 ..< resultWords: putI64Le(output, word, results[word])
  int64(outputBytes)
