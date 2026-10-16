const
  MaxOperations = 512
  MaxEntries = 128
  MaxKey = 99_999'i64
  BucketCount = 16
  MaxInputLength = 1537
  FnvOffset = 0xcbf29ce484222325'u64
  FnvPrime = 0x100000001b3'u64
  ResultMask = 0x7fffffffffffffff'u64

proc hashByte(hash: uint64, byte: uint8): uint64 =
  (hash xor uint64(byte)) *% FnvPrime

proc hashI32(hashValue: uint64, value: int64): uint64 =
  var hash = hashValue
  let bits = cast[uint32](int32(value))
  for shift in countup(0, 24, 8):
    hash = hashByte(hash, uint8((bits shr shift) and 255))
  hash

proc hash_map_separate_chaining*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "hash_map_separate_chaining".} =
  if input == nil or length < 1 or length > csize_t(MaxInputLength):
    return -1
  let operationCount = input[0]
  if operationCount < 0 or operationCount > MaxOperations or
      length != csize_t(1 + 3 * operationCount):
    return -1

  var keys: array[MaxEntries, int64]
  var mappedValues: array[MaxEntries, int64]
  var next: array[MaxEntries, int]
  var buckets: array[BucketCount, int]
  var freeSlots: array[MaxEntries, int]
  for index in 0 ..< MaxEntries:
    next[index] = -1
    freeSlots[index] = index
  for index in 0 ..< BucketCount:
    buckets[index] = -1
  var freeCount = MaxEntries
  var size = 0
  var hash = FnvOffset

  for operation in 0 ..< int(operationCount):
    let opcode = input[1 + 3 * operation]
    let key = input[2 + 3 * operation]
    let value = input[3 + 3 * operation]
    var resultCode = 0'u8
    var returnedValue = 0'i64

    if opcode == 0:
      if key < 0 or key > MaxKey or value < int64(low(int32)) or value > int64(high(int32)):
        return -1
      let bucket = int(key mod int64(BucketCount))
      var entry = buckets[bucket]
      while entry >= 0 and keys[entry] != key:
        entry = next[entry]
      if entry >= 0:
        mappedValues[entry] = value
      else:
        if size >= MaxEntries:
          return -1
        dec freeCount
        entry = freeSlots[freeCount]
        keys[entry] = key
        mappedValues[entry] = value
        next[entry] = buckets[bucket]
        buckets[bucket] = entry
        inc size
    elif opcode == 1:
      if key < 0 or key > MaxKey or value != 0:
        return -1
      let bucket = int(key mod int64(BucketCount))
      var entry = buckets[bucket]
      while entry >= 0 and keys[entry] != key:
        entry = next[entry]
      if entry >= 0:
        resultCode = 1
        returnedValue = mappedValues[entry]
    elif opcode == 2:
      if key < 0 or key > MaxKey or value != 0:
        return -1
      let bucket = int(key mod int64(BucketCount))
      var previous = -1
      var entry = buckets[bucket]
      while entry >= 0:
        let following = next[entry]
        if keys[entry] == key:
          if previous < 0: buckets[bucket] = following
          else: next[previous] = following
          freeSlots[freeCount] = entry
          inc freeCount
          dec size
          break
        previous = entry
        entry = following
    elif opcode == 3:
      if key < 0 or key > MaxKey or value != 0:
        return -1
      let bucket = int(key mod int64(BucketCount))
      var entry = buckets[bucket]
      while entry >= 0 and keys[entry] != key:
        entry = next[entry]
      resultCode = if entry >= 0: 1'u8 else: 0'u8
    elif opcode == 4:
      if key != 0 or value != 0:
        return -1
      for index in 0 ..< BucketCount: buckets[index] = -1
      for index in 0 ..< MaxEntries:
        next[index] = -1
        freeSlots[index] = index
      freeCount = MaxEntries
      size = 0
    else:
      return -1

    hash = hashByte(hash, uint8(opcode))
    hash = hashByte(hash, resultCode)
    if opcode == 1 and resultCode == 1:
      hash = hashI32(hash, returnedValue)
  cast[int64](hash and ResultMask)
