const MaxOperations = 128
const MaxCapacity = 16
const MaxInputLength = 387
const FnvOffset = 14695981039346656037'u64
const FnvPrime = 1099511628211'u64

proc hashResponses(responses: array[MaxOperations, int32], count: int): int64 =
  var hashValue = FnvOffset
  hashValue = (hashValue xor uint64(uint8(count))) *% FnvPrime
  hashValue = (hashValue xor uint64(uint8(count shr 8))) *% FnvPrime
  for index in 0 ..< count:
    let bits = cast[uint32](responses[index])
    for shift in countup(0, 24, 8):
      hashValue = (hashValue xor uint64(uint8(bits shr shift))) *% FnvPrime
  int64(hashValue and 0x7fff_ffff_ffff_ffff'u64)

proc mrucache*(input: ptr UncheckedArray[int64], length: csize_t): int64 {.cdecl, exportc: "mrucache".} =
  if input.isNil or length < 2 or length > csize_t(MaxInputLength): return -1
  let capacity64 = input[0]
  let operationCount64 = input[1]
  if capacity64 < 1'i64 or capacity64 > int64(MaxCapacity) or
      operationCount64 < 0'i64 or operationCount64 > int64(MaxOperations) or
      length != csize_t(2'i64 + 3'i64 * operationCount64): return -1
  let capacity = int(capacity64)
  let operationCount = int(operationCount64)
  var keys: array[MaxCapacity, int32]
  var values: array[MaxCapacity, int32]
  var responses: array[MaxOperations, int32]
  var cacheCount = 0
  var responseCount = 0

  for step in 0 ..< operationCount:
    let operation = input[2 + 3 * step]
    let key64 = input[3 + 3 * step]
    let value64 = input[4 + 3 * step]
    if operation < 0'i64 or operation > 1'i64 or key64 < int64(low(int32)) or key64 > int64(high(int32)) or
        value64 < int64(low(int32)) or value64 > int64(high(int32)): return -1
    let key = int32(key64)
    let value = int32(value64)
    var position = 0
    while position < cacheCount and keys[position] != key: inc position

    if operation == 0:
      if value < 0'i32 or value > 1_000_000'i32: return -1
      if position < cacheCount:
        for index in position ..< (cacheCount - 1):
          keys[index] = keys[index + 1]
          values[index] = values[index + 1]
        keys[cacheCount - 1] = key
        values[cacheCount - 1] = value
      else:
        if cacheCount == capacity: dec cacheCount
        keys[cacheCount] = key
        values[cacheCount] = value
        inc cacheCount
    elif position == cacheCount:
      responses[responseCount] = -1
      inc responseCount
    else:
      let response = values[position]
      for index in position ..< (cacheCount - 1):
        keys[index] = keys[index + 1]
        values[index] = values[index + 1]
      keys[cacheCount - 1] = key
      values[cacheCount - 1] = response
      responses[responseCount] = response
      inc responseCount

  hashResponses(responses, responseCount)
